import csv
import pandas as pd
from time import sleep
from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.wait import WebDriverWait
from lxml import etree

browser = webdriver.Chrome(executable_path='./chromedriver')
wait = WebDriverWait(browser,10)
def index_page(page):
    print('正在爬取第',page,'页')
    try:
        url='http://bang.dangdang.com/books/bestsellers/01.00.00.00.00.00-24hours-0-0-1-'+str(page)
        browser.get(url)
        page_text_list=[]
        #捕获当前页面对应的页面源码数据
        page_text = browser.page_source
        sleep(1)
        page_text_list.append(page_text)
        get_booklist(page_text)
    except TimeoutException:
        index_page(page)
# 解析商品列表
def get_booklist(page_text):
    tree = etree.HTML(page_text)
    li_list = tree.xpath('/html/body/div[3]/div[3]/div[2]/ul/li')
    for li in li_list:
        rank = li.xpath('./div[1]/text()')[0],
        name = li.xpath('./div[@class="name"]/a/text()')[0],
        pic = li.xpath('./div[@class="pic"]//img/@src')[0],
        pinglun = li.xpath('./div[@class="star"]//a/text()'),
        tuijian = li.xpath('./div[@class="star"]//span[@class="tuijian"]/text()')[0],
        author = li.xpath('./div[@class="publisher_info"]/a/text()')[0],
        date = li.xpath('./div[@class="publisher_info"]/span/text()')[0],
        price = li.xpath('./div[@class="price"]//span[@class="price_r"]/text()')[0],
        price_s = li.xpath('./div[@class="price"]//span[@class="price_s"]/text()')[0],
        try:
            e_book = li.xpath('./div[@class="price"]/p[@class="price_e"]/span/text()')[0]
        except:
            e_book = "null"
        csvWrite([rank,name,pic,pinglun,tuijian,author,date,price,price_s,e_book])






def csvWrite(item):
    with open("dangdang_data.csv", "a", encoding="utf-8", newline="") as f:
        csv.writer(f).writerow(item)



if __name__ == '__main__':
    with open("dangdang_data.csv", "w", encoding="utf-8", newline="") as fp:
        csv.writer(fp).writerow(['排名', '书名', '图片', '评论数', '推荐', '作者', '日期', '原价', '折扣', '电子书'])
    for page in range(1,3):
        index_page(page)
