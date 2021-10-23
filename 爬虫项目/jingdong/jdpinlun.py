from time import sleep
import requests
import csv
import random

productId = input("请输入商品ID:")
url = "https://club.jd.com/comment/productPageComments.action?"
headers = {
        'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36'
    }
for i in range(1,30):
    sleep(random.choice([2, 2.5, 3, 3.5]))
    params = {
        'productId': productId,
        'score': 0,
        'sortType': 5,
        'page': i,
        'pageSize': 10
    }

    text = requests.get(url=url,headers=headers,params=params).json()
    data = text['comments']
    for dd in data:
        sleep(random.choice([2, 2.5, 3, 3.5]))
        dic = {}
        dic["nickname"] = dd["nickname"]
        dic["productColor"] = dd["productColor"]
        dic["productSize"] = dd["productSize"]
        dic["replyCount"] = dd["replyCount"]
        dic["usefulVoteCount"] = dd["usefulVoteCount"]
        dic["content"] = dd["content"]
        dic["creationTime"] = dd["creationTime"]
        sleep(random.choice([2, 2.5, 3, 3.5]))
        with open('./jd_comments.csv','a',encoding='utf-8') as fp:
            writer = csv.DictWriter(fp, dic.keys())
            writer.writerow(dic)


#3028649