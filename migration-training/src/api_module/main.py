import sys
import requests
import os
import json
from time import sleep

def hello_world():
    return "Hello World"


class api_request(object):

    def __init__(self, api_token):
        self.all_members = []
        self.api_token = api_token
        self.header = {"token": self.api_token}

    def get_users(self, page_num, last_page):
        endpoint = ("https://subdomain.assetsonar.com/members.api?page={0}"
                    .format(page_num))
        r = requests.get(endpoint, headers=self.header)
        response = r.json()
        self.all_members.append(response)
        if page_num <= last_page:
            self.get_users(page_num+1, last_page)

    def turn_off_email(self):
        for page in self.all_members:
            self.update_users(page)

    def update_users(self, page):
        for user in page:
            if user['email'] == 'email@example.com':
                continue
            payload = {'user[email]': user['email'],
                       'user[first_name]': user['first_name'],
                       'user[last_name]': user['last_name'],
                       'user[role_id]': user['role_id'],
                       'user[subscribed_to_emails]': 'false',
                       'skip_confirmation_email': 'true'}
            endpoint = ("https://subdomain.assetsonar.com/members/{0}.api"
                        .format(user['id']))
            r = requests.put(endpoint, headers=self.header, data=payload)
            response = r.json()
            if r.status_code != 200:
                print(response)
                sys.exit()

if __name__ == "__main__":
    hello_world()