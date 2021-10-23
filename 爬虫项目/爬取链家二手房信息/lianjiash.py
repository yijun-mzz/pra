from time import sleep
import csv
import pandas as pd
import requests
import random
from lxml import etree

def useragent():

    user_agents = [
        'Mozilla/5.0 (Windows; U; Windows NT 5.1; it; rv:1.8.1.11) Gecko/20071127 Firefox/2.0.0.11',
        'Opera/9.25 (Windows NT 5.1; U; en)',
        'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
        'Mozilla/5.0 (compatible; Konqueror/3.5; Linux) KHTML/3.5.5 (like Gecko) (Kubuntu)',
        'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.12) Gecko/20070731 Ubuntu/dapper-security Firefox/1.5.0.12',
        'Lynx/2.8.5rel.1 libwww-FM/2.14 SSL-MM/1.4.1 GNUTLS/1.2.9',
        'Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7 (KHTML, like Gecko) Ubuntu/11.04 Chromium/16.0.912.77 Chrome/16.0.912.77 Safari/535.7',
        'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:10.0) Gecko/20100101 Firefox/10.0',
    ]

    agent = random.choice(user_agents)

    return {
        'User-Agent': agent
    }

def get(url):
    sleep(random.choice([2, 2.5, 3, 3.5]))
    page = requests.get(url=url,headers=useragent()).text
    return page

def region_url(page):
    html = etree.HTML(page)
    li_list = html.xpath('//div[@data-role="ershoufang"]/div/a/@href')
    # reg = html.xpath('//div[@data-role="ershoufang"]/div/a/text()')
    sleep(random.choice([2, 2.5, 3, 3.5]))
    for li in li_list:
        # 每个区域的地址
        region_url = 'https://sh.lianjia.com'+ li
        sleep(random.choice([2, 2.5, 3, 3.5]))
        r = li.split('/')[2]
        print(r)
        for i in range(1,3):
            new_url = region_url + 'pg'+ str(i) + '/'
            print("第" + str(i) + "页")
            with open("./region_urls.csv", "a", encoding="utf-8") as fp:
                fp.write(new_url+'\n')

def get_page(region_url):
    page_text = get(region_url)
    page_detail = etree.HTML(page_text)
    # 获取当前页面下的30个url
    url_list = page_detail.xpath('//div[@class="title"]/a/@href')
    sleep(random.choice([2, 2.5, 3, 3.5]))
    for url in url_list:
        #print(url)
        with open("./detail_urls.csv", "a", encoding="utf-8") as fp:
            fp.write(url+'\n')

def parser_data(detail):

    data = etree.HTML(detail)
    sleep(random.choice([2, 2.5, 3, 3.5]))
    dic = {}
    try:
        dic["Layout"] = data.xpath('//div[@class="room"]/div[1]/text()')[0]
    except:
        dic["Layout"] = ""
    try:
        dic["Floor"] = data.xpath('/html/body/div[5]/div[2]/div[4]/div[1]/div[2]/text()')[0].split('/')[1].strip()[1:-1]
    except:
        dic["Floor"] = ""
    try:
        dic["Direction"] = data.xpath('//div[@class="type"]/div[1]/text()')[0]
    except:
        dic["Direction"] = ""
    try:
        dic["Renovation"] = data.xpath('//div[@class="base"]/div[2]//li[9]/text()')[0].strip()
    except:
        dic["Renovation"] = ""
    try:
        dic["Size"] = data.xpath('//div[@class="area"]/div[1]/text()')[0].strip()[:-2]
    except:
        dic["Size"] = ""
    try:
        dic["Year"] = data.xpath('//div[@class="area"]/div[2]/text()')[0].split('/')[0].strip()[:4]
    except:
        dic["Year"] = ""
    try:
        dic["Community"] = data.xpath('//div[@class="communityName"]/a[1]/text()')[0]
    except:
        dic["Community"] = ""
    try:
        dic["Price"] = data.xpath('/html/body/div[5]/div[2]/div[3]/span[1]/text()')[0]
    except:
        dic["Price"] = ""
    try:
        dic["Region"] = data.xpath('//div[@class="areaName"]/span[2]/a[1]/text()')[0]
    except:
        dic["Region"] = ""
    try:
        dic["District"] = data.xpath('//div[@class="areaName"]/span[2]/a[2]/text()')[0]
    except:
        dic["District"] = ""
    try:
        dic["Elevator"] = data.xpath('//div[@class="base"]/div[2]//li[11]/text()')[0].strip()
    except:
        dic["Elevator"] = ""
    print (dic)
    with open("./fangyuan.csv", "a", encoding="utf-8") as f:
        writer = csv.DictWriter(f, dic.keys())
        writer.writerow(dic)




if __name__ == "__main__":
    url = 'https://sh.lianjia.com/ershoufang/'
    page = get(url)
    region_url(page)
    page_urls=open("region_urls.csv", "r", encoding="utf-8").read()
    page_urls = page_urls.split("\n")[:-1]
    for ul in page_urls:
        parse_page = get_page(ul)
        parse_urls = open("detail_urls.csv", "r", encoding="utf-8").read()
        parse_urls = parse_urls.split("\n")[:-1]
        for ll in parse_urls:
            #print(ll)
            par_detail = get(ll)
            parser_data(par_detail)


    # page_url = 'https://sh.lianjia.com/ershoufang/107104450261.html'
    # page_detail = get(page_url)
    # parser_data(page_detail)


