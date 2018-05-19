import psycopg2
import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
import re
from utils import sql_conn

res = sql_conn.execute("SELECT item_id FROM public.items")

lookup_list = [i[0] for i in res]

def lookup_item(item_id):
    
    df = None
    
    metadata = {}
    metadata['id'] = item_id
    
    template = 'http://services.runescape.com/m=itemdb_oldschool/viewitem?obj={}'
    url = template.format(item_id)
    
    try:
        resp = requests.get(url, timeout=10)

        if 'your IP address has been temporarily blocked' in resp.content:
            print "blocked!"
            return None, None
        
        soup = BeautifulSoup(resp.content, "lxml")
        
        title = soup.find("title").text
        metadata['page title'] = title.split(" - ")[0]
        
        # this works for both members and f2p
        description = soup.find(class_ = "item-description")
        
        item_name = description.find("h2").text
        metadata['name'] = item_name
        
        item_examine = description.find("p").text
        metadata['examine'] = item_examine

        icon_link = soup.find_all("img", {"alt" : item_name})[0].attrs['src']
        icon_data = requests.get(icon_link).content
        metadata['icon'] = icon_data

        stats = soup.find(class_ = "stats")
        item_price = stats.find("h3").find("span").attrs['title']
    
        item_price = int(item_price.replace(",",""))
        metadata['price'] = item_price
        
        # get trade info
        def parse_trade_data(js_lines):
            
            # parse one line
            def parse_js(line):
                # average180.push([new Date('2018/04/05'), 192, 190]);
                #   trade180.push([new Date('2018/04/21'), 6574]);
                data = {}
                if "average180" in line:
                    data['date'] = line.split("'")[1]
                    data['daily'] = line.split(", ")[1]
                    data['average'] = line.split(", ")[2].split("]")[0]
                elif "trade180" in line:
                    data['date'] = line.split("'")[1]
                    data['total'] = line.split(", ")[1].split("]")[0]
                return data
            trade = pd.DataFrame([parse_js(line) for line in js_lines if "trade180.push" in line])
            price = pd.DataFrame([parse_js(line) for line in js_lines if "average180.push" in line])
            trade.index = pd.to_datetime(trade['date'])
            price.index = pd.to_datetime(price['date'])
            df = pd.concat([trade['total'], price[['daily','average']]], axis=1)
            colmap = {
                'daily' : 'daily price',
                'average' : 'rolling average',
                'total' : 'trade count'
            }
            df.rename(columns = colmap, inplace=True)
            df = df.astype(int)
            return df
        
        js_lines = soup.find(class_ = "content").find("script").text.split("\r\n")
        df = parse_trade_data(js_lines)
    
    except KeyboardInterrupt:
        raise
            
    except:
        pass
    
    return metadata, df

for item_id in lookup_list:
    time.sleep(10)
    metadata, df = lookup_item(item_id) 
    if df is None:
        print item_id
        continue
    sql_conn.execute("DELETE FROM public.items WHERE item_id = %s", (item_id,))
    sql_conn.execute("INSERT INTO public.items(item_id, name, price, examine, icon) VALUES (%s, %s, %s, %s, %s)", (metadata['id'], metadata['name'], metadata['price'], metadata['examine'], psycopg2.Binary(metadata['icon'])) )
    print item_id, metadata['name']    
