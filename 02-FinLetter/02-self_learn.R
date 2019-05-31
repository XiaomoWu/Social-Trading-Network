# ��SP�����е��ֳַ����࣬learn-trade & self-trade ----
ld(cube.rb) # 45s
ld(f.cu)
ld(f.stk.risk)
# rb�����е��ּ�¼�ı�ġ����ַ��ȡ�����
# 1���ų�ipo�б꽻�ף�2��ֻ�������뽻�ף�3��һ���ν���ֻ���㵱���ۼ�ֵ��4��rb�е�stock.symbolֻ������f.stk.risk�г��ֹ���
rb <- cube.rb[, .(cube.symbol, cube.type, stock.symbol, date = as.Date(datetime), pre.weight = as.numeric(prev.weight.adjusted), target.weight)
    ][is.na(pre.weight), pre.weight := 0
    ][str_sub(stock.symbol, 3, 8) %in% f.stk.risk$stkcd
    ][target.weight > pre.weight, .(amt = sum(target.weight - pre.weight)), keyby = .(cube.symbol, cube.type, stock.symbol, date)
    ][f.cu[, .(cube.symbol, user.id)], on = .(cube.symbol), nomatch = 0] 
#rm(cube.rb)
sv(rb)

# Summary: ���ַ���
rb[, .(amt = mean(amt)), keyby = .(cube.type)]

# ����follow��ϵ
ld(f.user.stock)
ld(f.cu) # cid��owner�Ĺ�ϵ
f.cu[, cube.type := str_sub(cube.symbol, 1, 2)] # Ϊf.cu����cube.type����

# follow��SP���Լ��ĵ�����neighbor�ĵ��ַŵ�ͬһ�����ݼ���
follow <- f.user.stock[cube.type == "ZHCN", .(user.id, cube.symbol = symbol, create.date) # ZHCH����ZH��SP
    ][f.cu[, .(cube.symbol, owner.id = user.id)], on = .(cube.symbol), nomatch = 0][user.id != owner.id][, owner.id := NULL][user.id %in% f.cu[cube.type == "SP", user.id] # 1��ֻ����SP owner��follow��2���޳��Լ�follow�Լ������
    ][rb[, .(cube.symbol, stock.symbol, date, amt)], on = .(cube.symbol), nomatch = 0][order(user.id, cube.symbol, date)# ��rb��follow�����¼merge����
    ][rb[cube.type == "SP", .(user.id, stock.symbol, spbuy.date = date, spbuy.amt = amt)], on = .(user.id, stock.symbol), nomatch = 0
    ][order(user.id, cube.symbol, date, spbuy.date)] %>% unique() # ��rb��user.id�����¼merge����
sv(follow)

# Summary: Followerÿ�ܽ��ܵ�signal��
#follow[, cube.type := str_sub(cube.symbol, 1, 2)
    #][cube.type == "SP", .(.N/uniqueN(cube.symbol)), keyby = .()]


# 1 = [-30, -16], 2 = [16, 30], 3 = [ -15, -1], 4 = [1, 15]
# amt: ���ڴ�ֵ��signal������Ч
ld(follow)
ld(rb)
learn.trade <- follow[amt >= 25
    ][between(spbuy.date, date - 30, date - 16), signal := 1
    ][between(spbuy.date, date - 15, date - 1), signal := 3
    ][between(spbuy.date, date + 1, date + 15), signal := 4
    ][between(spbuy.date, date + 16, date + 30), signal := 2
    ][!is.na(signal)
    ][order(user.id, stock.symbol, spbuy.date, signal),
    .SD[1], keyby = .(user.id, stock.symbol, spbuy.date)]

# rb.sp���������ݼ�����learn.trade��rb.sp�ϲ������ͬһ��������ͬһֻ��Ʊ����ô��learn=1���Ǳʽ���
rb.sp <- learn.trade[, .(user.id, stock.symbol, date = spbuy.date, signal)
    ][rb[cube.type == "SP"], on = .(user.id, stock.symbol, date)
    ][is.na(signal), signal := 0]
rb.sp[, table(signal)]
sv(rb.sp)


# ��һ�����н�����self/learning�ı���
#rb.sp[, sum(signal) / .N]

# ����learn/self trade��performance������ͼ ----
# dret, edret ȫ���� in decimal
ld(f.stk.dret)
ld(rb.sp)
rb.sp.nv <- rb.sp[, # ÿһ�ʽ��׶�����180���¼
    .(signal, end.date = seq(from = date, to = date + 180, by = "day"), amt), keyby = .(user.id, cube.symbol, stock.symbol = str_sub(stock.symbol, 3, 8), date)
    ][date != end.date # ���뵱������治����
    ][f.stk.dret[, .(stkcd, date, dret, edret)], on = .(stock.symbol = stkcd, end.date = date), nomatch = 0][order(user.id, cube.symbol, stock.symbol, date, end.date)][, ":="(nv = cumprod(1 + dret), t = seq_len(.N)), keyby = .(user.id, cube.symbol, stock.symbol, date)] # ��stk.dret�ϲ�

rb.sp.nv.plot <- rb.sp.nv[date >= "2016-07-01", .(dret = sum(dret * (amt / sum(amt))), edret = sum(edret * (amt / sum(amt)))), keyby = .(signal, t)][order(signal, t)][, .(t, dret, edret, nv = cumprod(1 + dret), nv2 = cumprod(1 + edret)), keyby = .(signal)]

# t.test���������ߵ��������Ƿ��в��
#t.test(rb.sp.nv.plot[learn == 0 & t <= 120, dret * 100], rb.sp.nv.plot[learn == 1 & t <= 120, dret] * 100)

# Summary: daily / cummulative return
# average daily
rb.sp.nv.plot[, .(ret = mean(edret) * 100), keyby = .(signal)]
# cumulative
rb.sp.nv.plot[t == 90, .(ret = (nv2 - 1) * 100 ), keyby = .(signal)]

# 1 = [-30, -16], 2 = [16, 30], 3 = [ -15, -1], 4 = [1, 15]
ret <- rb.sp.nv.plot[t <= 90 & signal %in% c(0, 2)] %>%
    ggplot(aes(x = t, y = edret * 100, linetype = as.factor(signal), color = as.factor(signal))) +
    theme_bw() +
    geom_point(size = 2.25) +
    geom_line(size = 0.75) +
    scale_color_discrete(name = "", labels = c("Benchmark", "Lagging: 2-4 weeks")) +
    scale_linetype_discrete(name = "", labels = c("Benchmark", "Lagging: 2-4 weeks")) +
    xlab('') +
    ylab("Daily Excess Return (%)") +
    scale_x_continuous(breaks = c(0, 30, 60, 90)) +
    theme(legend.position = "bottom")

nv <- rb.sp.nv.plot[t <= 90 & signal %in% c(0, 2)] %>%
    ggplot(aes(x = t, y = nv2, linetype = as.factor(signal), color = as.factor(signal))) +
    theme_bw() +
    geom_line(size = 0.75) +
    scale_color_discrete(name = "", labels = c("Benchmark", "Lagging: 2-4 weeks")) +
    scale_linetype_discrete(name = "", labels = c("Benchmark", "Lagging: 2-4 weeks"))
    xlab('') +
    ylab("Cumulative Performance") +
    scale_x_continuous(breaks = c(0, 30, 60, 90)) +
    theme(legend.position = "bottom")

multiplot(ret, nv, cols = 2)
#ggsave("0_1.jpg")


# �����ǰ�������ȫ����һ��ͼ��
#ggplot() +
    #theme_bw() +
    #geom_line(data = rb.sp.nv.plot[t <= 120 & signal == 0], aes(x = t, y = nv), color = "#FFCC00", size = 1) +
    #geom_line(data = rb.sp.nv.plot[t <= 120 & signal == 1], aes(x = t, y = nv), color = "#FF3300", size = 1, linetype = "solid") +
     #geom_line(data = rb.sp.nv.plot[t <= 120 & signal == 3], aes(x = t, y = nv), color = "#FF9999", size = 1, linetype = "solid") +
     #geom_line(data = rb.sp.nv.plot[t <= 120 & signal == 2], aes(x = t, y = nv), color = "#0099FF", size = 1, linetype = 5) +
     #geom_line(data = rb.sp.nv.plot[t <= 120 & signal == 4], aes(x = t, y = nv), color = "#0033FF", size = 1, linetype = 5) +
    #xlab("") +
    #ylab("Cumulative Performance")