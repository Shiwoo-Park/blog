#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
마크다운 파일에 Jekyll Front Matter를 자동으로 추가하는 스크립트
"""

import os
import re
from pathlib import Path
from datetime import datetime

# 제외할 디렉토리
EXCLUDE_DIRS = {'archive', 'node_modules', '.git', 'resources', 'snippets', 'docs', 'job_specs'}

# 제외할 파일
EXCLUDE_FILES = {
    'README.md',
    'readme.md',
    'favorite.md', 
    'blog_migration_guide.md', 
    'jekyll_setup_guide.md',
    '_sample.md',
    '_post_template.md'
}

# 카테고리 매핑 (경로 -> 카테고리)
CATEGORY_MAP = {
    'posts/dev/ai': ['dev', 'ai'],
    'posts/dev/aws': ['dev', 'aws'],
    'posts/dev/backend': ['dev', 'backend'],
    'posts/dev/devops': ['dev', 'devops'],
    'posts/dev/etc': ['dev', 'etc'],
    'posts/dev/frontend': ['dev', 'frontend'],
    'posts/dev/git': ['dev', 'git'],
    'posts/dev/history': ['dev', 'history'],
    'posts/dev/python': ['dev', 'python'],
    'posts/dev/python/django': ['dev', 'python', 'django'],
    'posts/dev/python/pydantic': ['dev', 'python', 'pydantic'],
    'posts/dev/python/sqlalchemy': ['dev', 'python', 'sqlalchemy'],
    'posts/dev/python/unittest': ['dev', 'python', 'unittest'],
    'posts/dev/python/mywork': ['dev', 'python', 'mywork'],
    'posts/dev/storage': ['dev', 'storage'],
    'posts/invest': ['invest'],
    'posts/travel': ['travel'],
    'posts/travel/thai': ['travel', 'thai'],
    'posts/travel/vietnam': ['travel', 'vietnam'],
    'posts/etc': ['etc'],
}


def get_date_from_file(file_path):
    """파일 수정 시간에서 날짜 추출"""
    mtime = os.path.getmtime(file_path)
    return datetime.fromtimestamp(mtime).strftime('%Y-%m-%d')


def extract_title_from_filename(file_path):
    """파일명에서 제목 추출"""
    name = Path(file_path).stem
    # 언더스코어를 공백으로, 각 단어 첫 글자 대문자
    return name.replace('_', ' ').replace('-', ' ').title()


def get_categories_from_path(file_path):
    """경로에서 카테고리 추출"""
    path_str = str(Path(file_path).parent)
    # Windows 경로 처리
    path_str = path_str.replace('\\', '/')
    
    # 정확한 매칭 시도
    for path_pattern, categories in CATEGORY_MAP.items():
        if path_pattern in path_str:
            return categories
    
    # 부분 매칭
    if 'posts/dev/python' in path_str:
        if 'django' in path_str:
            return ['dev', 'python', 'django']
        elif 'pydantic' in path_str:
            return ['dev', 'python', 'pydantic']
        elif 'sqlalchemy' in path_str:
            return ['dev', 'python', 'sqlalchemy']
        else:
            return ['dev', 'python']
    elif 'posts/dev' in path_str:
        return ['dev']
    elif 'posts/invest' in path_str:
        return ['invest']
    elif 'posts/travel' in path_str:
        return ['travel']
    elif 'posts/etc' in path_str:
        return ['etc']
    else:
        return []


def has_frontmatter(content):
    """이미 Front Matter가 있는지 확인"""
    content = content.strip()
    return content.startswith('---') and '\n---' in content[:200]


def add_frontmatter_to_md(file_path):
    """마크다운 파일에 Front Matter 추가"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"파일 읽기 오류 ({file_path}): {e}")
        return False
    
    # 이미 front matter가 있으면 스킵
    if has_frontmatter(content):
        print(f"⏭️  스킵 (이미 Front Matter 있음): {file_path}")
        return False
    
    # 파일명에서 제목 추출
    title = extract_title_from_filename(file_path)
    
    # 날짜 추출
    date = get_date_from_file(file_path)
    
    # 카테고리 추출
    categories = get_categories_from_path(file_path)
    
    # Front Matter 생성
    categories_str = '[' + ', '.join([f'"{cat}"' for cat in categories]) + ']' if categories else '[]'
    
    frontmatter = f"""---
layout: post
title: "{title}"
date: {date}
categories: {categories_str}
---

"""
    
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(frontmatter + content)
        print(f"✅ 처리 완료: {file_path}")
        return True
    except Exception as e:
        print(f"❌ 파일 쓰기 오류 ({file_path}): {e}")
        return False


def main():
    """메인 함수"""
    print("=" * 60)
    print("Jekyll Front Matter 자동 추가 스크립트")
    print("=" * 60)
    print()
    
    processed = 0
    skipped = 0
    errors = 0
    
    # 현재 디렉토리부터 시작
    for root, dirs, files in os.walk('.'):
        # 제외할 디렉토리 필터링
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.')]
        
        for file in files:
            if file.endswith('.md') and file not in EXCLUDE_FILES:
                file_path = os.path.join(root, file)
                result = add_frontmatter_to_md(file_path)
                
                if result:
                    processed += 1
                elif result is False:
                    skipped += 1
                else:
                    errors += 1
    
    print()
    print("=" * 60)
    print(f"처리 완료: {processed}개")
    print(f"스킵: {skipped}개")
    print(f"오류: {errors}개")
    print("=" * 60)


if __name__ == '__main__':
    main()

