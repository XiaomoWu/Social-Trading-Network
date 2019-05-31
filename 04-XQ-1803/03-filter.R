# ����Ҫ��˳��ִ�У����ܵ���������
# ���� cube.ret�����඼������211-PC������
# ���ű����ڶ� r-prefix.mst������1803������ȥ�ء���ϴ�������޳�������С����ֵ��cube�����������ɵ� f-prefix ����project-JEP

# ����cid�����ڶ�cube������޳� ----
ld(r.cube.info.mst.1803)
# 0. cube.symbol���ظ�����Ϊ����������ץȡ�ļ�¼����ѡ��lastcrawl���
cube.info <- r.cube.info.mst.1803[order(cube.symbol, -lastcrawl)
    ][, .SD[1], keyby = .(cube.symbol)]
rm(r.cube.info.mst.1803)

# 1. r.cube.info: market = 'cn'
cid.cn <- cube.info[market == 'cn', unique(cube.symbol)]
sv(cid.cn) # 1,174,004 cubes

# 2. abnormal return
# ��ֵ��͵�1%�Լ���ֵ����150���޳�
cid.abret <- cube.info[net.value %between% c(quantile(net.value, 0.01), 150), unique(cube.symbol)]
sv(cid.abret)

# 3. exists in cube.rb
# r.cube.rb�Ѿ�����ȥ�ش���������Ҫ��ȥ�ء�������Ϣ���£�
#> uniqueN(r.cube.rb.mst.1803, by = c("cube.symbol"))
#[1] 1261068
#> uniqueN(r.cube.rb.mst.1803, by = c("cube.symbol", "stock.id", "created.at"))
#[1] 47430187
#> uniqueN(r.cube.rb.mst.1803, by = c("id"))
#[1] 46538666
#> uniqueN(r.cube.rb.mst.1803)
#[1] 47461455 == nrow(r.cube.rb.mst.1803)
ld(r.cube.rb.mst.1803)
cid.rb <- r.cube.rb.mst.1803[, unique(cube.symbol)]
sv(cid.rb)

# 4. exists in cube.ret
ld(r.cube.ret.mst.1803)
cid.ret <- r.cube.ret.mst.1803[, unique(cube.symbol)]
sv(cid.ret)
rm(r.cube.ret.mst.1803)

# 5. ʹ���������ɵ�cid.abret, cid.cn, cid.rb, cid.ret�������յ�cid
ld(cid.abret)
ld(cid.cn)
ld(cid.ret)
ld(cid.rb)
cid <- intersect(cid.abret, cid.cn) %>% intersect(cid.rb) %>% intersect(cid.ret)
sv(cid)


# ����uid�����ڶ�user������޳� ----
# 1. ֻ��cid��owner�ſ��ܳ�Ϊuid
uid.cidowner <- cube.info[cube.symbol %in% cid, unique(owner.id)]
sv(uid.cidowner)

# 2. exists in r.user.info
# r.user.info�е�user.id���ظ���ѡ��lastcrawl����Ǹ�
ld(r.user.info.mst.1803)
user.info <- r.user.info.mst.1803[order(user.id, - lastcrawl)][, .SD[1], keyby = .(user.id)]
uid.userinfo <- user.info[, unique(user.id)]
sv(uid.userinfo)
rm(r.user.info.mst.1803)

# 3. exists in r.user.stock
# r.user.stock��Ҫȥ�أ��������� ��user.id, code, createAt������������ͬ������£�ѡ��lastcrawl���
# ע�⣬stockName�ǲ�׼�ģ���Ϊ��˾���ܸ�����������ͬһ�ҹ�˾��stockName��ͬ��code��ͬ����������Ϣ���£�
# uniqueN(r.user.stock.mst.1803, by = c("user.id", "code", "createAt")) # 33378799
ld(r.user.stock.mst.1803)
user.stock <- r.user.stock.mst.1803[order(user.id, code, createAt, - lastcrawl)][, .SD[1], keyby = .(user.id, code, createAt)]
rm(r.user.stock.mst.1803)
uid.userstock <- user.stock[, unique(user.id)]
sv(uid.userstock)

# ʹ���������ɵ�uid.cidowner, uid.userinfo�������յ�uid
ld(uid.cidowner)
ld(uid.userinfo)
ld(uid.userstock)
uid <- intersect(uid.cidowner, uid.userinfo) %>% intersect(uid.userstock)
sv(uid)

# ʹ��cid��uid���� f-prefix ----
# ����cube.info
# ����fans.count��1
f.cube.info.mst.1803 <- cube.info[cube.symbol %in% cid][, ":="(fans.count = (fans.count - 1))]
rm(f.cube.info.mst.1803, cube.info)

# ����f.cube.rb
ld(r.cube.rb.mst.1803)
f.cube.rb.mst.1803 <- r.cube.rb.mst.1803[cube.symbol %in% cid
    ][, ":="(prev.weight.adjusted = as.numeric(prev.weight.adjusted))]
rm(r.cube.rb.mst.1803)
# target.weight��prev.weightֻ����NA������[0,110]֮�����
# ��ʱ��֪ʲôԭ��prev.weight������΢����100����ʱ�������
f.cube.rb.mst.1803 <- f.cube.rb.mst.1803[(is.na(target.weight) | target.weight %between% c(0, 110)) & (is.na(prev.weight.adjusted) | prev.weight.adjusted %between% c(0, 110))]
rm(f.cube.rb.mst.1803)

# ����user.info
f.user.info.mst.1803 <- user.info[user.id %in% uid]
sv(f.user.info.mst.1803)
rm(user.info, f.user.info.mst.1803)

# ����user.stock
f.user.stock.mst.1803 <- user.stock[user.id %in% uid]
f.user.stock.mst.1803 <- f.user.stock.mst.1803[, .(user.id, stock.symbol = code, cube.type = exchange, create.date = as.Date(as.POSIXct(createAt / 1000, origin = "1970-01-01")), buy.price = buyPrice, sell.price = sellPrice, is.notice = isNotice, target.percent = targetPercent)]
sv(f.user.stock.mst.1803)
rm(user.stock, f.user.stock.mst.1803)

# ����f.cube.ret 
# ���� cube.ret ʵ��̫��ֻ����211-Server�д���
ld(r.cube.ret.mst.1803)
f.cube.ret.mst.1803 <- r.cube.ret.mst.1803[cube.symbol %in% cid
    ][order(cube.symbol, date)]
rm(r.cube.ret.mst.1803)
# ���� quit / re-enter, ��f.cube.ret���н�һ���޳�
# life����Ϊ��һ�������һ��֮���ʱ��, f.cubelife����ÿ����ϵ�����ʱ���Լ�����
# life���ٴ���1
ld(f.cube.rb.mst.1803)
f.cubelife.mst.1803 <- f.cube.rb.mst.1803[, .(start = as.IDate(min(created.at)), end = as.IDate(max(created.at)), trade.n = .N), keyby = .(cube.symbol)
    ][, ":="(life = as.integer(end - start))
    ][life >= 1]
# cid.1day: cube.symbols that last for more than one day
cid.1day <- unique(f.cubelife.mst.1803$cube.symbol)
sv(f.cubelife.mst.1803)
sv(cid.1day)

# �� life>=1 �������Ӧ���� f.cube.info, f.cube.rb ----
ld(cid.1day)
ld(f.cube.info.mst.1803)
ld(f.cube.rb.mst.1803)

f.cube.ret.mst.1803 <- f.cube.ret.mst.1803[cube.symbol %in% cid.1day]
f.cube.info.mst.1803 <- f.cube.info.mst.1803[cube.symbol %in% cid.1day]
f.cube.rb.mst.1803 <- f.cube.rb.mst.1803[cube.symbol %in% cid.1day]

sv(f.cube.ret.mst.1803)
sv(f.cube.info.mst.1803)
sv(f.cube.rb.mst.1803)

# ����year-week��date֮��Ķ�Ӧ�� f.yw�����ڻ�ͼ ----
ld(f.cube.ret.mst.1803)
f.ywd.mst.1803 <- f.cube.ret.mst.1803[, .(date = unique(date))][order(date)][, ":="(year = year(date), week = week(date))][, tail(.SD, 1), keyby = .(year, week)]
sv(f.ywd.mst.1803)

# ����cube������ ----
ld(f.cube.ret.mst.1803)
# ����������
f.cube.wret.mst.1803 <- f.cube.ret.mst.1803[, ":="(year = year(date), week = week(date))
    ][order(cube.symbol, year, week, - date)
    ][, .SD[1], keyby = .(cube.symbol, year, week)
    ][, ":="(wret = growth(value) * 100), keyby = cube.symbol
    ][, ":="(label = NULL, date = NULL)
    ] %>% na.omit()
sv(f.cube.wret.mst.1803) 