# url='https://search.jd.com/Search?keyword=月饼&page=1'
# 'https://search.jd.com/Search?keyword=月饼&page=3'
# 'https://search.jd.com/Search?keyword=月饼&page=5'
# 当前页面*2-1

from selenium import webdriver
from selenium.webdriver import ChromeOptions
from time import sleep
from lxml import etree
import csv
import random



def browser():
    option = ChromeOptions()
    option.add_experimental_option('prefs', {'profile.managed_default_content_settings.images': 2})  # 禁止图片加载，加快速度
    option.add_argument('--headless')
    option.add_argument('--disable-gpu')  # 设置无头浏览器
    bro = webdriver.Chrome(executable_path='C:/Program Files (x86)/chromedriver', options=option)
    return bro


def get_data(bro):
    bro.maximize_window()  # 最大化浏览
    url = "https://search.jd.com/Search?keyword=%s" % (key)
    bro.get(url)
    bro.execute_script('window.scrollTo(0, document.body.scrollHeight)')  # 向下滑动一屏
    sleep(random.choice([2, 2.5, 3, 3.5]))
    page = bro.find_element_by_xpath('//div[@id="J_bottomPage"]/span[2]/em/b').text
    for i in range(1,3):
        sleep(random.choice([2, 2.5, 3, 3.5]))
        print("-" * 30 + "已获取第%s页数据" %(i) + "-" *30)
        pro_url = "https://search.jd.com/Search?keyword=%s&page=%d" % (key,i*2-1)
        print("第" + str(i) + "页")
        bro.get(url)
        parser_data(bro)  # 解析数据
    bro.quit()

def parser_data(bro):
    data = bro.page_source
    html = etree.HTML(data)
    li_list = html.xpath('//ul[@class="gl-warp clearfix"]/li')
    sleep(random.choice([2, 2.5, 3, 3.5]))
    dic = {}
    for li in li_list:
        try:
            dic["title"] = li.xpath('./div/div[@class="p-name p-name-type-2"]/a/em//text()')
        except:
            dic["title"] = ""
        try:
            dic["commit"] = li.xpath('./div/div[@class="p-commit"]/strong/a/text()')[0]
        except:
            dic["commit"] = ""
        try:
            dic["shop"] = li.xpath('./div/div[@class="p-shop"]/span/a/text()')[0]
        except:
            dic["shop"] = ""
        try:
            dic["price"] = li.xpath('./div/div[@class="p-price"]/strong/i/text()')[0]
        except:
            dic["price"] = ""
        try:
            dic["detail"] = "https:" + li.xpath('./div/div[@class="p-name p-name-type-2"]/a/@href')[0]
        except:
            dic["detail"] = ""
        print(dic)
        sleep(random.choice([2, 2.5, 3, 3.5]))
        with open("./jd_pro.csv","a",encoding="utf-8") as fp:
            writer = csv.DictWriter(fp, dic.keys())
            writer.writerow(dic)



if __name__ == "__main__":
    key = input("请输入要采集商品的关键字:")
    chrome_bro = browser()
    url_list = get_data(chrome_bro)








