# django DRF - exception handler

```python
import copy
import logging
import traceback
from typing import Optional, Dict, List

from django.core.cache import cache
from django.core.exceptions import ObjectDoesNotExist, ValidationError
from rest_framework import status
from rest_framework.exceptions import (
    ValidationError as DRFValidationError,
    APIException,
    AuthenticationFailed,
)
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import exception_handler

from silva.choices_enum import ChoicesEnum
from silva.consts import (
    CacheKey,
    EXCEPTION_HANDLER_SLACK_SNOOZE_TIMEOUT_SEC,
    EXCEPTION_HANDLER_SLACK_MSG_REPEAT_LIMIT,
    EXCEPTION_HANDLER_SLACK_MESSAGE_ARG_LENGTH_LIMIT,
)
from silva.utils import get_client_ip

file_logger = logging.getLogger("file")
slack_logger = logging.getLogger("slack")

# View name 에 해당 문자열이 포함되는 경우 슬랙알림 skip
SLACK_NOTIFICATION_SKIP_VIEW_STR_LIST = ["TestViewSet", "TestAPIView"]

# logging 시, 에러 스택을 같이 남길 필요가 없는 Exception 클래스명
ERROR_STACK_LOGGING_SKIP_EXCEPTION = ["NotAuthenticated", "PermissionDenied"]

DJANGO_DEFAULT_NOT_FOUND_ERROR_TEXT = "matching query does not exist"


class StatusCodeErrorMessage(ChoicesEnum):
    BAD_REQUEST = (status.HTTP_400_BAD_REQUEST, "잘못된 요청입니다.")
    UNAUTHORIZED = (status.HTTP_401_UNAUTHORIZED, "계정 아이디 및 비밀번호를 다시 확인해주세요.")
    FORBIDDEN = (status.HTTP_403_FORBIDDEN, "권한이 없습니다.")
    NOT_FOUND = (status.HTTP_404_NOT_FOUND, "리소스를 찾을 수 없습니다.")
    INTERNAL_SERVER_ERROR = (
        status.HTTP_500_INTERNAL_SERVER_ERROR,
        "오류가 발생했습니다. 관리자에게 문의하세요",
    )


class ExceptionHandlingService:
    @staticmethod
    def get_specific_exception_message(exc: Exception) -> Optional[str]:
        """
        특정한 타입의 Exception 에서,
        원하는 형태의 메시지를 만들어야 하는 경우 사용
        """
        message = None

        if isinstance(exc, AuthenticationFailed):
            message = StatusCodeErrorMessage.UNAUTHORIZED.text

        elif isinstance(exc, DRFValidationError):
            if isinstance(exc.detail, dict):
                key = list(exc.detail.keys())[0]
                key_detail = exc.detail[key][0]
                message = key_detail.replace("이 필드", f"{key} 필드")

        if message is None and isinstance(exc, APIException):
            if type(exc).__name__ == "APIException":
                if APIException().detail != str(exc.detail):
                    message = str(exc.detail)
            else:
                # APIException 를 상속받은 "자식 클래스" 일때만 !!!
                if isinstance(exc.detail, list):
                    message = exc.detail[0]
                elif isinstance(exc.detail, dict):
                    key = list(exc.detail.keys())[0]
                    key_detail = exc.detail[key][0]
                    message = f"{key}: {key_detail}"
                else:
                    message = str(exc.detail)

        return message

    @classmethod
    def set_request_info(
        cls,
        request: Request,
        text_list: List,
        arg_list: List,
        useful_context_info: Dict,
    ) -> None:
        """
        로깅 context 에 request 객체에서 얻을 수 있는 유용한 정보들을 추가
        """

        text_list.append(f"\n- request: `[%s] %s`")
        method = str(request.method).upper()
        useful_context_info["http_method"] = method
        useful_context_info["request_path"] = request.path
        arg_list.append(method)
        arg_list.append(request.path)

        http_origin = request.META.get("HTTP_ORIGIN")
        if http_origin:
            text_list.append(f"\n- Origin: `%s`")
            useful_context_info["http_origin"] = http_origin
            arg_list.append(http_origin)

        user = request.user
        if user.is_authenticated:
            text_list.append("\n- user: `[#%s] %s - {email: %s, is_staff: %s}`")
            useful_context_info["user_id"] = user.id
            useful_context_info["user_username"] = user.username
            useful_context_info["user_email"] = user.email
            useful_context_info["user_is_staff"] = user.is_staff
            arg_list.append(user.id)
            arg_list.append(user.username)
            arg_list.append(user.email)
            arg_list.append(user.is_staff)

        client_ip = get_client_ip(request)
        if client_ip:
            text_list.append(f"\n- Client IP: `%s`")
            useful_context_info["client_ip"] = client_ip
            arg_list.append(client_ip)

        # User Agent 로깅
        # : 그다지 효용성이 없는것 같아서 주석처리 (나중에 필요하면 추가)
        # user_agent = request.META.get("HTTP_USER_AGENT", None)
        # if user_agent:
        #     text_list.append(f"\n- User Agent: `%s`")
        #     useful_context_info["user_agent"] = user_agent
        #     arg_list.append(user_agent)

        # 요청 Data logging
        if method in ("POST", "PUT", "PATCH"):
            text_list.append(f"\n- request data: `%s`")
            useful_context_info["request_data"] = request.data
            arg_list.append(request.data)
        elif method == "GET":
            text_list.append(f"\n- request params: `%s`")
            useful_context_info["request_query_params"] = request.query_params.dict()
            arg_list.append(request.query_params.dict())

    @classmethod
    def get_context_info(cls, context) -> Dict:
        """
        exception handler 에서 context 내부 유용한 정보들을
        슬랙 발송하기 좋은 형태로 변경하여 리턴
        """
        useful_fields = ["view", "args", "kwargs", "request"]
        useful_context_info = {}
        text_list = []
        arg_list = []
        is_test_view = False

        for field in useful_fields:
            if field in context and context[field]:
                if field == "request":
                    cls.set_request_info(
                        context["request"], text_list, arg_list, useful_context_info
                    )
                elif field == "view":
                    text_list.append(f"\n- view: `%s`")
                    view_name = type(context[field]).__name__
                    for s in SLACK_NOTIFICATION_SKIP_VIEW_STR_LIST:
                        if s in view_name:
                            is_test_view = True
                            break
                    useful_context_info["view"] = view_name
                    arg_list.append(view_name)
                else:
                    text_list.append(f"\n- {field}: `%s`")
                    useful_context_info[field] = context[field]
                    arg_list.append(context[field])

        return {
            "is_test_view": is_test_view,
            "text_list": text_list,
            "arg_list": arg_list,
            "useful_info_dic": useful_context_info,
        }

    @staticmethod
    def get_slack_text(s: str, allow_newline=True):
        """
        Slack 알림 발송 시, json decode 에러문제에 대한 전처리
        - 따옴표, 외따옴표 (", ') 제거
        - 개행문자 escape (\n -> \\n)
        """
        s = str(s)
        remove_chars = ['"', "'"]
        if not allow_newline:
            remove_chars.append("\n")
        for rm_char in remove_chars:
            s = s.replace(rm_char, "")
        replace_chars = {"\n": "\\n"}
        for asis, tobe in replace_chars.items():
            s = tobe.join(s.split(asis))
        return s

    @classmethod
    def get_is_slack_send(cls, http_method, request_path, exc_name):
        """
        Slack 메시지 보낼건지 여부 결정

        - 동일한 에러 알림이 피로할정도로 너무 많이 오는것을 방지하기위해
        - 정해진 횟수만큼만 메시지가 발송되고
        - 일정시간 동안 알람을 자동으로 중지시키도록 처리
        """
        is_slack_send = True
        # 캐시키로 사용할 path 문자열 생성
        # ex. /test/123/server-error -> test_server_error
        request_path_cache_key = "_".join(
            part
            for part in request_path.replace("/", "_").replace("-", "_").split("_")
            if not part.isdigit()
        ).strip("_")
        cache_key = CacheKey.EXCEPTION_HANDLER_SLACK_SNOOZE.code.format(
            http_method=http_method,
            request_path=request_path_cache_key,
            exception_name=exc_name,
        )
        same_error_count = cache.get(cache_key)
        if same_error_count is None:
            cache.set(cache_key, 1, EXCEPTION_HANDLER_SLACK_SNOOZE_TIMEOUT_SEC)
        elif same_error_count >= EXCEPTION_HANDLER_SLACK_MSG_REPEAT_LIMIT:
            is_slack_send = False
        else:
            cache.set(
                cache_key,
                same_error_count + 1,
                EXCEPTION_HANDLER_SLACK_SNOOZE_TIMEOUT_SEC,
            )

        return is_slack_send

    @classmethod
    def apply_length_limit(cls, slack_args: List):
        """Slack 메시지가 너무 길어서 적당한 길이로 자르기"""
        for i, elem in enumerate(slack_args):
            length_limit = EXCEPTION_HANDLER_SLACK_MESSAGE_ARG_LENGTH_LIMIT
            if len(elem) <= length_limit:
                continue

            if "Traceback" in elem:  # error stack 의 경우 뒤쪽에 중요 정보가 있어서 뒤에서부터 자르기
                slack_args[i] = f"전문 생략 ...\\n{elem[-length_limit:]}"
            else:
                slack_args[i] = f"{elem[:length_limit]}..."

        return slack_args

    @classmethod
    def get_organized_log_info(
        cls,
        exc: Exception,
        context,
        error_stack_trace: str,
        error_in_exception_handling: Exception,
    ) -> Dict:
        """
        파일 로깅, Slack 발송을 위한 문자열 정보 생성
        """
        log_text_list = [
            "===============================================",
            "\n- exception: `[%s] %s`",
        ]
        exception_msg = cls.get_slack_text(str(exc), allow_newline=False)
        exception_cls_name = type(exc).__name__
        log_args = [exception_cls_name, exception_msg]

        context_info = cls.get_context_info(context)
        useful_info_dic = context_info["useful_info_dic"]
        useful_info_dic["exception_cls_name"] = exception_cls_name
        log_text_list += context_info["text_list"]
        log_args += context_info["arg_list"]

        if error_stack_trace:
            log_text_list.append(f"\n```\n%s```")
            log_args.append(error_stack_trace)

        if error_in_exception_handling:
            log_text_list.append(f"\n- error in silva_exception_handler(): `%s`")
            log_args.append(error_in_exception_handling)

        normal_log_text = "".join(log_text_list)
        is_slack_send = cls.get_is_slack_send(
            useful_info_dic["http_method"],
            useful_info_dic["request_path"],
            exception_cls_name,
        )

        return {
            "is_test_view": context_info["is_test_view"],
            "normal_text": normal_log_text,
            "normal_args": log_args,
            "is_slack_send": is_slack_send,
            "slack_text": cls.get_slack_text(normal_log_text),
            "slack_args": cls.apply_length_limit(
                [cls.get_slack_text(elem) for elem in log_args]
            ),
        }


def silva_exception_handler(exc, context):
    response_status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_message = StatusCodeErrorMessage.INTERNAL_SERVER_ERROR.text
    response_data = {
        "message": default_message,
        "errors": None,
    }
    error_in_exception_handling = None

    try:
        response = exception_handler(exc, context)

        if isinstance(response, Response):
            response_status_code = response.status_code
            response_data["errors"] = response.data

        # 특정 exception class 일때 status_code override
        if isinstance(exc, ValidationError):
            response_status_code = status.HTTP_400_BAD_REQUEST
        if isinstance(exc, ObjectDoesNotExist):
            response_status_code = status.HTTP_404_NOT_FOUND
            response_data["errors"] = str(exc)
            if DJANGO_DEFAULT_NOT_FOUND_ERROR_TEXT not in response_data["errors"]:
                # error 메시지 직접 입력 하였을 경우
                response_data["message"] = str(exc)

        # 특정 exception 일때 message override
        specific_message = ExceptionHandlingService.get_specific_exception_message(exc)
        if specific_message is not None:
            response_data["message"] = specific_message

        # 기본 message 일 경우, 가능하다면 status code 에 맞게 수정
        if (
            response_data["message"] == default_message
            and response_status_code != status.HTTP_500_INTERNAL_SERVER_ERROR
        ):
            response_data["message"] = StatusCodeErrorMessage.get_text(
                response_status_code, default_message
            )

    except Exception as e:
        # exception handling 중 exception 발생한 경우
        error_in_exception_handling = e

    finally:
        error_stack_trace = ""
        exception_name = type(exc).__name__
        if exception_name not in ERROR_STACK_LOGGING_SKIP_EXCEPTION:
            error_stack_trace = traceback.format_exc()

        if response_status_code == status.HTTP_500_INTERNAL_SERVER_ERROR:
            try:
                log_info = ExceptionHandlingService.get_organized_log_info(
                    exc, context, error_stack_trace, error_in_exception_handling
                )
                file_logger.error(log_info["normal_text"], *log_info["normal_args"])

                # unittest 돌릴때 발생하는 500 에러는 슬랙알림 skip
                if not log_info["is_test_view"] and log_info["is_slack_send"]:
                    slack_logger.error(log_info["slack_text"], *log_info["slack_args"])

            except Exception as e:
                traceback.print_exc()
                log_msg = (
                    "[Exception] exc=%s, context=%s,"
                    " error in get_organized_log_info()=%s"
                )
                log_args = [exc, context, e]
                file_logger.error(log_msg, *log_args)
                slack_logger.error(
                    log_msg,
                    *[
                        ExceptionHandlingService.get_slack_text(str(elem))
                        for elem in log_args
                    ],
                )
        else:
            log_msg = f"[Exception] exc: {exc}\ncontext: {context}"
            if error_stack_trace:
                log_msg = f"{log_msg}\n{error_stack_trace}"

            print(log_msg)  # 자체 콘솔 로깅 (삭제 X)
            file_logger.error(log_msg)

        return Response(status=response_status_code, data=response_data)
```