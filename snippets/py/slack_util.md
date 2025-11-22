
# Python: Slack 메시지 유틸리티

```python
"""
Slack Message 를 보낼때 사용하는 유틸모듈
- SlackMessageUtil 을 사용하여 메세지를 보내고
- 채널 목록은 SlackChannel 으로 관리
- Slack Bot 이 메세지를 남겨준다
"""

import logging
import traceback
from concurrent.futures._base import TimeoutError as ConcurrentTimeoutError
from typing import List

from django.conf import settings
from django.utils import timezone
from slack_sdk import WebClient

from Baropharm.utils.choices_enum import ChoicesEnum

logger = logging.getLogger(__name__)
DEFAULT_REQUEST_TIMEOUT = 3


class SlackChannel(ChoicesEnum):
    """
    메세지를 보낼 슬랙 채널들
    - 테스트 환경 | 리얼 환경 을 구분하여 정의

    <용법>
    환경에 맞는 채널 찾아내는법
    >>> channel = slack_util.get_channel(SlackChannel.ADMIN_PUSH)
    또는 아래 함수 활용
    >>> SlackMessageUtil.send_formatted_auto("title", "content", SlackChannel.ADMIN_PUSH)
    """

    # 목적 = (테스트환경_채널명, 설명, 운영환경_채널명)
    DEFAULT = ("dev-test", "기본값", "dev-test")
    ORDER_ERROR = ("order-test", "주문 관련 오류", "order-errors")
    SERVICE_ERROR = ("service-test", "서비스 관련 오류", "service-errors")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.at_test_env = args[0]
        self.at_real_env = args[2]


class SlackMessageUtil:
    client_args = {
        "token": settings.SLACK_TOKEN,
        "timeout": DEFAULT_REQUEST_TIMEOUT,
    }
    client = WebClient(**client_args)

    @classmethod
    def get_client(cls):
        return cls.client

    @classmethod
    def get_channel(cls, channel_enum: SlackChannel):
        if settings.ENV in ["prod"]:
            return channel_enum.at_real_env
        return channel_enum.at_test_env

    @classmethod
    def send(
        cls,
        text: str,
        channel: str = SlackChannel.DEFAULT.code,
        blocks: List = (),
        attachments: List = (),
    ):
        """
        가장 기본적인 슬랙 메시징 기능을 제공하는 함수
        - 운영환경이 아닐경우 자동으로 @channel 제거

        :return: slack 응답 객체
        """

        # 자동 채널 알림 제거
        if settings.ENV != "prod":
            text = text.replace("<!channel>", "")

        try:
            response = cls.client.chat_postMessage(
                channel=channel, text=text, blocks=blocks, attachments=attachments
            )
            if not response["ok"]:
                logger.warning(f"Slack 메세지 전송 실패: response={response}")

            return response
        except ConcurrentTimeoutError as te:
            # slackclient 의 TimeoutError: 미해결 이슈 - 로깅만 한다
            # https://github.com/slackapi/python-slackclient/issues/476
            logger.warning(
                f"Slack 메세지 전송 실패: 슬랙 서버 타임아웃 오류 (채널={channel}, 내용={text})"
            )
        except Exception:
            logger.warning(
                f"Slack 메세지 전송 실패: 채널={channel}, 내용={text}, 알 수 없는 오류={traceback.format_exc()}"
            )

    @classmethod
    def send_formatted(
        cls,
        main_message: str,
        info_message: str,
        channel: str = SlackChannel.DEFAULT.code,
        is_channel_notice: bool = False,
    ):
        """
        제목과 내용으로 이루어진 특정 양식의 슬랙 알림 메세지를 보낸다
        - 서버 환경과 타임스탬프를 기본적으로 자동 추가한다
        - 실서버가 아닌경우, 채널 노티 구문을 자동으로 제거한다
        - 텍스트 포매팅 레퍼런스
        https://api.slack.com/reference/surfaces/formatting#linking_to_channels_and_users

        :param main_message: 메세지 제목
        :param info_message: 메세지 상세내용
        :param is_channel_notice: 채널 알림 여부
        :param channel: 슬랙 채널 (기본값 #exid_bot)
        :return: 없음
        """
        now_date = timezone.now().strftime("%Y-%m-%d %H:%M:%S")

        message_list = [
            f"`[{now_date}] {settings.ENV}` ",
            " <!channel>\n" if is_channel_notice else "\n",
            f"{main_message}\n" if len(main_message.strip()) > 0 else "",
            f"```\n{info_message}\n```\n" if len(info_message.strip()) > 0 else "",
        ]
        return cls.send("".join(message_list), channel)

    @classmethod
    def send_formatted_auto(
        cls,
        main_message: str,
        info_message: str,
        channel: SlackChannel,
        is_channel_notice: bool = False,
    ):
        """
        서버 환경에 따라 따라 자동으로 전송 채널을 지정해준다
        나머지는 send_formatted() 와 동일
        """
        target_channel = cls.get_channel(channel)
        return SlackMessageUtil.send_formatted(
            main_message,
            info_message,
            channel=target_channel,
            is_channel_notice=is_channel_notice,
        )
```