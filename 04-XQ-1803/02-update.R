 # ���ű����ڽ���ץȡ�����ݺϲ�����������
# �������ݼ����� new ��׺��ԭ�����ݼ� old ��׺
# ����ִ�е������ǽ�1803�ϲ���1709 (��1703)
# ע�⣡��������ִ�к����ɵ����ݼ���r-�������ظ��Ĺ۲⣬������ 02-filter�н���ȥ��

# �ϲ�cube.info ----
# �������¾������ļ�
ld(r.cube.info.mst.1709, T)
r.cube.info.old <- r.cube.info
ld(r.cube.info.1803, T)
r.cube.info.new <- r.cube.info
# ���¾������ļ������š�ƴ�ӣ�������ÿһ�εļ�¼
r.cube.info <- rbindlist(list(r.cube.info.old, r.cube.info.new), use.names = T, fill = T) %>% unique()
# ���� lastcrawl����������2017-07������lastcrawl=1703��2017-07��2017-11������lastcrawl=1709��2017-11��2018-06������lastcrawl=1803��
r.cube.info.mst.1803 <- r.cube.info[, ":="(lastcrawl.date = as.Date(as.POSIXct(lastcrawl, origin = "1970-01-01")))
    ][, ":="(lastcrawl = ifelse(lastcrawl.date <= as.Date("2017-07-01"), 1703,
        ifelse(lastcrawl.date <= as.Date("2017-11-01"), 1709, 1803)))
    ][, ":="(lastcrawl.date = NULL)]
# ����symbol��update.date�����Ժ�Ҫ����ʱ��ֱ��r.cube.info[, .SD[1], keyby = .(cube.symbol)] ���ɵ������µļ�¼
setorder(r.cube.info.mst.1803, cube.symbol, -update.date)
sv(r.cube.info.mst.1803)

# �ϲ�cube.ret ----
# Must run in 211-Server!!!
# ���Ǵ�r.cube.ret.1803����ȡ���ڴ��� 2017-07-01�Ĺ۲⣬Ȼ��rbindlist�� r.cube.ret.mst.1709
ld(r.cube.ret.1803, T)
r.cube.ret.1803.append <- r.cube.ret.1803[date >= as.Date("2017-07-01")]
rm(r.cube.ret.1803)
ld(r.cube.ret.mst.1709, T)
# ������� cube.type����ô�ڴ�ͷŲ�����
#r.cube.ret.1803.append[, ':='(cube.type = NULL)]
#r.cube.ret.mst.1709[, ':='(cube.type = NULL)]

r.cube.ret.mst.1803 <- rbindlist(list(r.cube.ret.1803.append, r.cube.ret.mst.1709), use.names = T, fill = T) %>% unique(by = c('cube.symbol', 'date')) %>% setorder(cube.symbol, date)

rm(r.cube.ret.1803.append)
rm(r.cube.ret.mst.1709)
sv(r.cube.ret.mst.1803)

# �ϲ�cube.rb ----
# �������¾������ļ���������Ϊ������ old ��׺
ld(r.cube.rb.1803, T)
ld(r.cube.rb.mst.1709, T)

# ���¾������ļ������š�ƴ�ӣ�������ÿһ�εļ�¼
r.cube.rb.mst.1803 <- rbindlist(list(r.cube.rb.mst.1709, r.cube.rb.1803), use.names = T, fill = T)
rm(r.cube.rb.1803, r.cube.rb.mst.1709)

# ȥ��
r.cube.rb.mst.1803 <- unique(r.cube.rb.mst.1803, by = c("id", "rebalancing.id", "cube.symbol", "stock.symbol", "price", "created.at", "target.weight", "prev.weight.adjusted")) # distinct "id": 47461455

sv(r.cube.rb.mst.1803)

# �ϲ�user.fans ----
# �������¾������ļ���������Ϊ������ old ��׺
ld(r.user.fans.1803, T)
ld(r.user.fans.mst.1709, T)

# mst.1709 ��lastcrawl ��POSIXct���ĳ�int��1709 or 1703��
r.user.fans.mst.1709[, ":="(last = ifelse(lastcrawl <= as.Date("2017-07-01"), 1703,
        ifelse(lastcrawl <= as.Date("2017-11-01"), 1709, 1803)))
        ][, ":="(lastcrawl = NULL)]
setnames(r.user.fans.mst.1709, "last", "lastcrawl")

# ���¾������ļ������š�ƴ�ӣ�������ÿһ�εļ�¼
r.user.fans.mst.1803 <- rbindlist(list(r.user.fans.mst.1709, r.user.fans.1803), use.names = T, fill = T)
# ����user.id��lastcrawl���� ���Ժ�Ҫ����ʱ��ֱ��r.user.fans[, .SD[1], keyby = .(user.id)] ���ɵ������µļ�¼
setkey(r.user.fans.mst.1803, user.id, lastcrawl)
sv(r.user.fans.mst.1803)

# �ϲ�user.follow ----
# �������¾������ļ�
ld(r.user.follow.1803, T)
ld(r.user.follow.mst.1709, T)

# mst.1709 ��lastcrawl ��date���ĳ�int��1709 or 1703��
r.user.follow.mst.1709[, ":="(last = ifelse(lastcrawl <= as.Date("2017-07-01"), 1703,
        ifelse(lastcrawl <= as.Date("2017-11-01"), 1709, 1803)))
        ][, ":="(lastcrawl = NULL)]
setnames(r.user.follow.mst.1709, "last", "lastcrawl")

# ���¾������ļ������š�ƴ�ӣ�������ÿһ�εļ�¼
r.user.follow.mst.1803 <- rbindlist(list(r.user.follow.mst.1709, r.user.follow.1803), use.names = T, fill = T)
# ����user.id��lastcrawl���� ���Ժ�Ҫ����ʱ��ֱ��r.user.follow[, .SD[1], keyby = .(user.id)] ���ɵ������µļ�¼
setkey(r.user.follow.mst.1803, user.id, lastcrawl)
sv(r.user.follow.mst.1803)

# �ϲ�user.info ----
# �������¾������ļ�
ld(r.user.info.mst.1709, T)
ld(r.user.info.1803, T)

# mst.1709 ��lastcrawl ��date���ĳ�int��1709 or 1703��
r.user.info.mst.1709[, ":="(last = ifelse(lastcrawl <= as.Date("2017-07-01"), 1703,
        ifelse(lastcrawl <= as.Date("2017-11-01"), 1709, 1803)))
        ][, ":="(lastcrawl = NULL)]
setnames(r.user.info.mst.1709, "last", "lastcrawl")

# ���¾������ļ������š�ƴ�ӣ�������ÿһ�εļ�¼
r.user.info.mst.1803 <- rbindlist(list(r.user.info.mst.1709, r.user.info.1803), use.names = T, fill = T)
# ����user.id��lastcrawl�����Ժ�Ҫ����ʱ��ֱ��dt[, .SD[1], keyby = .(user.id, lastcrawl)] ���ɵ������µļ�¼
setorder(r.user.info.mst.1803, user.id, lastcrawl)
sv(r.user.info.mst.1803)

# �ϲ�user.info.weibo ----
# �������¾������ļ�
ld(r.user.info.weibo.mst.1709, T)
ld(r.user.info.weibo.1803, T)

# mst.1709 ��lastcrawl ��date���ĳ�int��1709 or 1703��
r.user.info.weibo.mst.1709[, ":="(last = ifelse(lastcrawl <= as.Date("2017-07-01"), 1703,
        ifelse(lastcrawl <= as.Date("2017-11-01"), 1709, 1803)))
        ][, ":="(lastcrawl = NULL)]
setnames(r.user.info.weibo.mst.1709, "last", "lastcrawl")

# ���¾������ļ������š�ƴ�ӣ�������ÿһ�εļ�¼
r.user.info.weibo.mst.1803 <- rbindlist(list(r.user.info.weibo.mst.1709, r.user.info.weibo.1803), use.names = T, fill = T) %>% unique()
# ����user.id��lastcrawl�����Ժ�Ҫ����ʱ��ֱ��dt[, .SD[1], keyby = .(user.id, lastcrawl)] ���ɵ������µļ�¼
setorder(r.user.info.weibo.mst.1803, user.id, lastcrawl)
sv(r.user.info.weibo.mst.1803)

# �ϲ�user.stock ----
# �������¾������ļ�
ld(r.user.stock.mst.1709, T)
ld(r.user.stock.1803, T)

# mst.1709 ��lastcrawl ��date���ĳ�int��1709 or 1703��
r.user.stock.mst.1709[, ":="(last = ifelse(lastcrawl <= as.Date("2017-07-01"), 1703,
        ifelse(lastcrawl <= as.Date("2017-11-01"), 1709, 1803)))
        ][, ":="(lastcrawl = NULL)]
setnames(r.user.stock.mst.1709, "last", "lastcrawl")

# ���¾������ļ������š�ƴ�ӣ�������ÿһ�εļ�¼
r.user.stock.mst.1803 <- rbindlist(list(r.user.stock.mst.1709, r.user.stock.1803), use.names = T, fill = T)
# ����user.id��lastcrawl�����Ժ�Ҫ����ʱ��ֱ��r.cube.stock[, .SD[1], keyby = .(cube.symbol)] ���ɵ������µļ�¼
setorder(r.user.stock.mst.1803, user.id, lastcrawl)
sv(r.user.stock.mst.1803)

# �ϲ�user.cmt ----
# �������¾������ļ�
ld(r.user.cmt.1709, T)
ld(r.user.cmt.1803, T)

# ���¾������ļ������š�ƴ��
# ����������ӵ� id, title, text��һ������ô������Ϊ������һ���ģ�ֻ������һ��ʹ��unique������

# ע�⣡������Ȼ������ r-prefix�����Ǿ�����ȥ�ز���������

r.user.cmt.mst.1803 <- rbindlist(list(r.user.cmt.1709, r.user.cmt.1803), use.names = T, fill = T) %>% unique(by = c("id", "title", "text"))

setorder(r.user.cmt.mst.1803, id, lastcrawl)
sv(r.user.cmt.mst.1803)

