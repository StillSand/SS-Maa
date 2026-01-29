#!/usr/bin/env python3
"""
动态获取 GitHub 仓库的最新 Release 版本
"""
import requests
import sys
import json

def get_latest_release(repo_owner, repo_name):
    """
    获取 GitHub 仓库的最新 Release 版本
    
    Args:
        repo_owner: 仓库所有者
        repo_name: 仓库名称
    
    Returns:
        dict: 包含 tag_name, version, assets 等信息
    """
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/releases/latest"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        return {
            'tag_name': data['tag_name'],
            'version': data['tag_name'].lstrip('v'),
            'name': data.get('name', ''),
            'published_at': data.get('published_at', ''),
            'assets': [
                {
                    'name': asset['name'],
                    'download_url': asset['browser_download_url'],
                    'size': asset['size']
                }
                for asset in data.get('assets', [])
            ]
        }
    except requests.exceptions.RequestException as e:
        print(f"Error fetching latest release: {e}", file=sys.stderr)
        return None

def find_asset_by_pattern(assets, pattern):
    """
    根据模式匹配查找资源
    
    Args:
        assets: 资源列表
        pattern: 匹配模式（字符串或列表）
    
    Returns:
        dict: 匹配的资源信息
    """
    if isinstance(pattern, str):
        pattern = [pattern]
    
    for asset in assets:
        for p in pattern:
            if p in asset['name']:
                return asset
    return None

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 get_latest_release.py <owner> <repo> [pattern]")
        print("Example: python3 get_latest_release.py MaaAssistantArknights maa-cli aarch64")
        sys.exit(1)
    
    owner = sys.argv[1]
    repo = sys.argv[2]
    pattern = sys.argv[3] if len(sys.argv) > 3 else None
    
    release = get_latest_release(owner, repo)
    
    if release:
        print(f"Latest version: {release['tag_name']}")
        
        if pattern:
            asset = find_asset_by_pattern(release['assets'], pattern)
            if asset:
                print(f"Asset: {asset['name']}")
                print(f"Download URL: {asset['download_url']}")
            else:
                print(f"No asset matching pattern '{pattern}' found", file=sys.stderr)
                sys.exit(1)
        else:
            # 输出所有资源
            for asset in release['assets']:
                print(f"- {asset['name']}: {asset['download_url']}")
    else:
        sys.exit(1)
