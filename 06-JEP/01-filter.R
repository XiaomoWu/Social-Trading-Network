#This project use f-prefixs which are genreated by project '04-XQ-1803'
#ֻ�������������ϴ��Ψһ��Ҫע���һ����ϴ�����ǡ�life>=1����������Ҫ���β���ͬһ��Ľ���

SDATE <- as.IDate('2016-07-01')
EDATE <- as.IDate('2018-04-01')

#f.stk.risk�� �����ÿ����Ʊ��vol��ivol���������ں�����Ʊ���յ����ݼ� ----
# �ȵ���������������ݡ��г�������
# ��Ʊ�������ݸ����� 1804
ld(dstk.mst.1804, T)
ld(d3f.mst.1804, T)
# �������� + �г����� 
ret <- dstk.mst.1804[, .(stkcd, trddt, dret = dretnd)
    ][d3f.mst.1804[markettypeid == 'P9709', .(trddt, rm = riskpremium1)], on = .(trddt), nomatch = 0]
rm(dstk.mst.1804, d3f.mst.1804)
# ����ÿ����Ʊ�ķ���measure��f.stk.risk
library(PerformanceAnalytics)
library(dplyr)

system.time({
stk.risk <- ret[trddt > as.Date('2015-01-01')
    ][, ':='(year = year(date), week = lubridate::isoweek(date))
    ][order(stkcd, trddt)
    ][, dret.100 := ntile(dret, 100),
    ][dret.100 %between% c(2, 99), # filter top/down 1% return outlie
    ][, {n <- 60; # 60-day rolling
        cat(.BY[[1]], '\n');
        if (.N > n) {lapply((n+1):.N, function(t) {sub.dret <- dret[(t - n):t];
            sub.rm <- rm[(t - n):t];
            skew <- skewness(sub.dret);
            vol <- sum(sub.dret ^ 2);
            fit <- lm(sub.dret ~ sub.rm);
            beta <- coef(fit)[[2]];
            ivol <- sd(resid(fit));
            list(date = trddt[t], beta = beta, skew = skew, vol = vol, ivol = ivol);
            }) %>% rbindlist()}
        else if (.N %between% c(20, n)) { # ��������ڴ���20�쵫С��60�죬ֱ����ǰ20���������
            sub.dret <- dret;
            sub.rm <- rm;
            skew <- skewness(sub.dret);
            vol <- sum(sub.dret ^ 2);
            fit <- lm(sub.dret ~ sub.rm);
            beta <- coef(fit)[[2]];
            ivol <- sd(resid(fit));
            list(date = trddt, beta = beta, skew = skew, vol = vol, ivol = ivol)}}, 
        keyby = .(stkcd)]
}) # 32 min
sv(stk.risk)
# ����decile���飬����ÿ�ܵ�risk
make_decile <- function(x) ntile(x, 10) %>% mean(na.rm = T) %>% round()
stk.wrisk <- f.stk.risk[order(stkcd, date)
    ][, ':='(beta = as.numeric(ntile(beta, 10)), skew = as.numeric(ntile(skew, 10)), vol = as.numeric(ntile(vol, 10)), ivol = as.numeric(ntile(ivol, 10)), week1stday = date[1], weeklastday = date[.N]), keyby = .(year, week)
    ][, .(beta = round(mean(beta)), skew = round(mean(skew)), vol = round(mean(vol)), ivol = round(mean(ivol)), week1stday = week1stday[1], weeklastday = weeklastday[1]), keyby = .(stkcd, year, week)]
sv(stk.wrisk)

# cube.rb ----
# ZHû�����ƣ�SPҪ��life >= 30 d
ld(f.cubelife.mst.1803)
ld(f.cube.rb.mst.1803)
cid.sp30d <- f.cubelife.mst.1803[str_sub(cube.symbol, 1, 2) == 'ZH' | (str_sub(cube.symbol, 1, 2) == 'SP' & life >= 30), unique(cube.symbol)]

cube.rb <- f.cube.rb.mst.1803[cube.symbol %in% cid.sp30d, .(cube.symbol, cube.type, stock.symbol = str_sub(stock.symbol, 3, 8), date = as.IDate(created.at), created.at, pre.weight = prev.weight.adjusted, target.weight)
    ][is.na(pre.weight), pre.weight := 0
    ][order(cube.symbol, created.at)
    ][, ':='(amt = target.weight - pre.weight, year = year(date), week = lubridate::isoweek(date))]
sv(cube.rb)

# f.cu: cube & user.id ----
ld(f.cube.info.mst.1803)
cu <- unique(f.cube.info.mst.1803, by = c('cube.symbol', 'cube.type', 'owner.id'))
sv(cu)

# ���� f.userlife ----
# userlife����Ϊ�����Ȱ�һ��user���е�cube���ܵ�һ�飬Ȼ����startΪ����cube������ʱ�䣬endΪ����cube�����һ�ʽ���ʱ�䣨��Ҫ���cubelife��
ld(f.cubelife.mst.1803)
ld(f.cube.info.mst.1803)
userlife <- f.cubelife.mst.1803[f.cube.info.mst.1803[, .(cube.symbol, user.id = owner.id)], nomatch = 0
    ][, .(start = min(start), end = max(end)), keyby = .(user.id)
    ][, ":="(life = as.integer(end - start))]
sv(userlife)

# f.user.nwk ----
# ɸѡ������follow�������ʵ�̣�Ȼ���������½����ۼӡ���ÿһ�й۲ⶼ������ǰ��/��������������Լ��ۼ�follow�����
# cube.type == ZHCN�Ȱ�����ϣ��ְ���ʵ��
ld(f.user.stock.mst.1803)
ld(f.cubelife.mst.1803)
ld(cu)

CJ <- f.cubelife.mst.1803[str_sub(cube.symbol, 1, 2) == 'SP', .(date = seq(start, end, by = "day")), keyby = .(cube.symbol)
    ][, .(cube.symbol, year = year(date), week = lubridate::isoweek(date))
    ] %>% unique() # Ϊ����һ��ʱ���ֵ

# user.wnwk.sp: ֻ���� SP �û�
# ÿ�ܽ���һ��nwk
sadd <- function(x) {
    if (length(x) == 1) {
        x
    } else {
        as.list(Reduce(union, x, accumulate = T))
    }
}
user.wnwk.sp <- f.user.stock.mst.1803[cube.type %in% c('ZHCN'), .(from.user.id = user.id, to.cube.symbol = stock.symbol, follow.date = create.date)
    ][, ":="(year = year(follow.date), week = lubridate::isoweek(follow.date))
    ][cu[cube.type == 'SP', .(from.cube.symbol = cube.symbol, owner.id)], on = .(from.user.id = owner.id), nomatch = 0
    ][, ':='(from.user.id = NULL)
    ][to.cube.symbol != from.cube.symbol
    ][, .(to.cube.symbol = list(to.cube.symbol)), keyby = .(from.cube.symbol, year, week)
    ][CJ, on = .(from.cube.symbol = cube.symbol, year, week), nomatch = NA
    ][, ':='(to.cube.symbol = sadd(to.cube.symbol)), keyby = .(from.cube.symbol)
    ][order(from.cube.symbol, year, week)]
sv(user.wnwk.sp)

# user.nwk�����������е��û�������������ֻ��һ��nwk����������ÿ������һ��nwk��
from <- f.user.stock.mst.1803[cube.type %in% c('ZHCN'), .(from.user.id = user.id, to.cube.symbol = stock.symbol, follow.date = create.date)
    ][, ":="(year = year(follow.date), week = lubridate::isoweek(follow.date))
    #][f.cubelife.mst.1803[, .(cube.symbol, to.start = start, to.end = end)], on = .(to.cube.symbol = cube.symbol), nomatch = 0
    ][cu[, .(from.cube.symbol = cube.symbol, owner.id)], on = .(from.user.id = owner.id), nomatch = 0, allow.cartesian = T
    ][order(year, week, from.cube.symbol)
    ][f.cubelife.mst.1803[, .(cube.symbol, from.start = start, from.end = end)], on = .(from.cube.symbol = cube.symbol), nomatch = 0
    ][from.start > follow.date]



[, ':='(from.user.id = NULL)
    ][to.cube.symbol != from.cube.symbol
    ][, .(to.cube.symbol = list(to.cube.symbol)), keyby = .(from.cube.symbol, year, week)
    ][CJ, on = .(from.cube.symbol = cube.symbol, year, week), nomatch = NA
    ][, ':='(to.cube.symbol = sadd(to.cube.symbol)), keyby = .(from.cube.symbol)
    ][order(from.cube.symbol, year, week)]
sv(user.wnwk)




a <- data.table(x = c(1, 2, 4))
b <- data.table(x = c(1, 1, 2, 4), y = c('a', 'b', 'c', 'd'))
a[b, on = .(x)]