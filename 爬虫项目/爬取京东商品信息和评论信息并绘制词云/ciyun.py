from wordcloud import WordCloud
import pandas as pd
import matplotlib.pyplot as plt
plt.style.use('fivethirtyeight')
plt.rc('figure',figsize=(20,8),dpi=80)
names=['nickname','productColor','productSize','replyCount','usefulVoteCount','content','creationTime']
df=pd.read_csv('jd_comments.csv',names=names)
font = r'C:\Windows\Fonts\simfang.ttf'
wc = WordCloud(font_path=font, background_color='White',width=1920,height=1080).generate(" ".join(df['content']))
plt.imshow(wc)
plt.axis("off")
plt.show()
