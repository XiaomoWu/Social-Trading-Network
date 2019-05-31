# ���ȵ������йɼ����� ----
#f.dret.stk <- trd.dalyr[markettype %in% c("1", "4", "16"), .(stkcd, date = trddt, price = clsprc, vol = dnshrtrd, amt = dnvaltrd, dret = dretnd, adjprice = adjprcnd, cap = dsmvosd)]
#sv(f.dret.stk)
ld(f.dret.stk) # cap: ����ͨ��ֵ�����������ʾ�Ϊ������������

# D/P Ratio (�Լ�д�������) ----
# ����������� date: Ԥ�������գ�sp���͹ɱ�����tr��ת��������div������
# ���ֺ�/�ֺ�һ��ռ�������� 40% �� 55%
div <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/��������/CD_Dividend.txt", encoding = 'UTF-8')
setnames(div, names(div), tolower(names(div)))
div <- div[, .(stkcd = sprintf("%06d", stkcd), finyr = finyear, disyr = disye, date = as.Date(ppdadt), div = btperdiv)
    ][order(stkcd, date)
    ][, .SD[.N], keyby = .(stkcd, finyr, disyr) # ���ĳЩ���������ظ�������ĳ��ı���������� disyr == 2����ȡʱ�����Ǹ���
    ][order(stkcd, date)
    ][!is.na(div), if.divdt := 1 # ��ǳ���Ϣ�ɷ���
    ][, ":="(yrgrp = cumsum(ifelse(disyr == 2, 1, 0))), keyby = .(stkcd)
    ][!is.na(date)] # ��Щ�Ƚ���Ĺ۲�����ȱʧ

# �Ժ����ļ�div�������ڲ�ֵ��ͬʱ����ÿ��������ۼƺ���
CJ <- div[, .(date = seq(min(date), max(date), by = "day")), keyby = stkcd]
div <- div[CJ, on = .(stkcd, date), nomatch = NA
    ][order(stkcd, date)
    ][is.na(div), div := 0
    ][is.na(if.divdt), if.divdt := 0
    ][, ":="(yrgrp = na.locf(yrgrp, na.rm = F)), keyby = stkcd
    ][, ":="(div = cumsum(div)), keyby = .(stkcd, yrgrp)]
rm(CJ)
# ��ɼ��ļ��ϲ�
div <- div[f.dret.stk[, .(stkcd, date, price)], on = .(stkcd, date), nomatch = 0
    ][, .(stkcd, date, div, price, dp = div/price)]
sv(div)

# �����й�Ʊ���հ���div����quintile��
divrank <- div[date >= as.Date("2010-01-01")
    ][dp == 0, ":="(divrank = 1)
    ][dp > 0, ":="(divrank = ntile(dp, 4) + 1), by = .(date)
    ][order(stkcd, date), .(stkcd, date, divrank)
    ] %>% unique(by = c("stkcd", "date"))
sv(divrank)
rm(div)

# PE/PB/PS Ratio��ֱ����CSMAR�����ݣ�----
pe <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/PE-PB-PS (CSMAR)/pe.txt", encoding = "UTF-8", header = T)
setnames(pe, names(pe), tolower(names(pe)))

# �� DP, PE, PS, PB, liq�������ԣ�����Խ��������Խ�ã� ����
# dp = 0 ˵��û�ֺ�
perank <- pe[tradingdate >= as.Date("2013-01-01")
    ][, .(stkcd = sprintf("%06d", symbol), date = as.Date(tradingdate), pe = fill_na(pe), pb = fill_na(pb), ps = fill_na(ps), liq = fill_na(liquidility))
    ][, .(stkcd, perank = ntile(pe, 5), pbrank = ntile(pb, 5), psrank = ntile(ps, 5), liqrank = ntile(liq, 5)), keyby = date
    ][order(stkcd, date)]
sv(perank)

# Capital (Size) ----
ld(f.dret.stk)
sizerank <- f.dret.stk[date >= as.Date("2010-01-01"), .(stkcd, sizerank = ntile(cap, 5)), keyby = .(date)
    ][order(stkcd, date)
    ] %>% unique(by = c("stkcd", "date"))
sv(sizerank)

# Momentum/Contrarian ----
# ��ȥһ�꣨180d�������/���Ĺ�Ʊ
ld(f.dret.stk)
stk <- f.dret.stk[date >= as.Date("2013-01-01"), .(stkcd, date, adjprice, end.date = date)]
setkey(stk, stkcd, date, end.date)
itvls <- copy(stk)[, ":="(date = date - 180)]
olps <- foverlaps(itvls, stk, type = "any", which = T, nomatch = 0)
pastret <- olps[, .(pastret = stk[yid, (adjprice[.N] / adjprice[1] - 1) * 100]), keyby = xid] # ��ʱ10����

retrank <- copy(stk)[pastret$xid, ":="(pastret = pastret$pastret)
    ][, ":="(end.date = NULL, adjprice = NULL)
    ][date >= as.Date("2014-01-01") # ����dret.stk���ݴ�2013-01-01��ʼ�㣬���ҹ�����Ϊ360�죬�����ʽ���õ����ݴ� 2014-01-01 ��ʼ
    ][, .(stkcd, retrank = ntile(pastret, 5)), keyby = .(date)
    ][order(stkcd, date)
    ] %>% unique(by = c("stkcd", "date"))
sv(retrank)

# risk (250�����)----
# ivol: �Լ��ù�Ʊ�۸����
ld(f.dret.stk)
ld(r.d3f)
# ���� doParallel
cl <- makeCluster(8)
registerDoParallel(cl)

system.time({ 
ivol.120d <- f.dret.stk[r.d3f[, .(date, rm = winsorize(rm, probs = c(0.01, 0.99)))], on = .(date), nomatch = 0
    ][, ":="(dret = winsorize(dret, probs = c(0.01, 0.99)))
    ][order(stkcd, date)
    ][date >= as.Date("2015-01-01"),
    {
        n <- 120 # 120-day rolling
        if (.N >= n) {
            foreach(t = (n + 1):.N, .final = rbindlist, .packages = "PerformanceAnalytics") %dopar% {
                sub.dret <- dret[(t - n):t]
                sub.rm <- rm[(t - n):t]
                skew <- skewness(sub.dret)
                vol <- sum(sub.dret ^ 2)
                fit <- lm(sub.dret ~ sub.rm)
                beta <- coef(fit)[[2]]
                ivol <- sd(resid(fit))
                list(date = date[t], beta = beta, skew = skew, vol = vol, ivol = ivol)
            }
        } else if (.N %between% c(20, n)) {
            sub.dret <- dret
            sub.rm <- rm
            skew <- skewness(sub.dret)
            vol <- sum(sub.dret ^ 2)
            fit <- lm(sub.dret ~ sub.rm)
            beta <- coef(fit)[[2]]
            ivol <- sd(resid(fit))
            list(date = date, beta = beta, skew = skew, vol = vol, ivol = ivol)
        }
    }, keyby = .(stkcd)]
})
sv(ivol.120d)
ivolrank <- ivol.120d[, .(stkcd, betarank = ntile(beta, 5), skewrank = ntile(skew, 5), volrank = ntile(vol, 5), ivolrank = ntile(ivol, 5)), keyby = date]

# (Deprecated, ����ȫ���Լ���) -- beta.vol���ݼ������� beta, volatility������GTA -- 
#beta.vol <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/RISK-rolling-250-day/risk.txt", encoding = "UTF-8", header = T)
#setnames(beta.vol, names(beta.vol), tolower(names(beta.vol)))
#beta.volrank <- beta.vol[, .(stkcd = sprintf("%06d", symbol), date = as.Date(tradingdate), beta = beta1, vol = volatility)
    #][, .(stkcd, betarank = ntile(beta, 5), volrank = ntile(vol, 5)), keyby = date
    #][order(stkcd, date)]


# ed���ݼ�������equity/debt
ed <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/��ծ����/Equity-Debt.txt", encoding = "UTF-8", header = T)
setnames(ed, names(ed), tolower(names(ed)))
ed <- ed[typrep == "A", .(stkcd = sprintf("%06d", as.numeric(stkcd)), typrep, date = as.Date(accper), ed = f011801a)][order(stkcd, date)]
CJ <- ed[, .(date = seq(min(date), max(date), by = "day")), keyby = stkcd]
ed <- ed[CJ, on = .(stkcd, date), nomatch = NA
    ][order(stkcd, date)
    ][, .(date, ed = na.locf(ed, na.rm = F)), keyby = stkcd]
edrank <- ed[, .(stkcd, edrank = ntile(ed, 5)), keyby = date
    ][order(stkcd, date)]
# ��edrank�ϲ���riskrank��
riskrank <- ivolrank[edrank, on = .(stkcd, date), nomatch = 0][order(stkcd, date)]
sv(riskrank)

# ӯ������ ----
# profitrank������ROE / ROA / Profit margin
profit <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/ӯ������/profitability.txt", encoding = "UTF-8", header = T)
setnames(profit, names(profit), tolower(names(profit)))
profit <- profit[typrep == "A", .(stkcd = sprintf("%06d", stkcd), date = as.Date(accper), typrep, roa = f050204c, roe = f050504c, profitmargin = f052301c)
    ][order(stkcd, date)
    ][, ":="(roa = na.locf(roa, na.rm = F), roe = na.locf(roe, na.rm = F), profitmargin = na.locf(profitmargin, na.rm = F)), keyby = stkcd
    ] %>% na.omit()

CJ <- profit[, .(date = seq(min(date), max(date), by = "day")), keyby = stkcd]
profitrank <- profit[CJ, on = .(stkcd, date), nomatch = NA
    ][order(stkcd, date)
    ][, ":="(roa = na.locf(roa, na.rm = F), roe = na.locf(roe, na.rm = F), profitmargin = na.locf(profitmargin, na.rm = F))
    ][, .(stkcd, roarank = ntile(roe, 5), roerank = ntile(roe, 5), profitmarginrank = ntile(profitmargin, 5)), keyby = date
    ][order(stkcd, date)]
sv(profitrank)

# Growth ----
# ����ͬ������, acc- ��ʾaccelerated growth����percentage growth
growth <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/��������/growh.txt", encoding = "UTF-8", header = T)
setnames(growth, names(growth), tolower(names(growth)))
growth <- growth[typrep == "A", .(stkcd = sprintf("%06d", stkcd), date = as.Date(accper), salesgrowth = f081602c, earninggrowth = f081002b, assetgrowth = f080602a)
    ][order(stkcd, date)
    ][, ":="(acc.salesgrowth = c(NA, diff(salesgrowth)), acc.earninggrowth = c(NA, diff(earninggrowth)), acc.assetgrowth = c(NA, diff(assetgrowth))), keyby = stkcd] # ���һ������accelerated growth

CJ <- growth[, .(date = seq(min(date), max(date), by = "day")), keyby = stkcd]
growthrank <- growth[CJ, on = .(stkcd, date), nomatch = NA
    ][order(stkcd, date)
    ][, .(date, salesgrowth = na.locf(salesgrowth, na.rm = F),
    earninggrowth = na.locf(earninggrowth, na.rm = F),
    assetgrowth = na.locf(assetgrowth, na.rm = F),
    acc.salesgrowth = na.locf(acc.salesgrowth, na.rm = F),
    acc.earninggrowth = na.locf(acc.earninggrowth, na.rm = F),
    acc.assetgrowth = na.locf(acc.assetgrowth, na.rm = F)), keyby = stkcd
    ][, .(stkcd, salesgrowthrank = ntile(salesgrowth, 5),
    earninggrowthrank = ntile(earninggrowth, 5),
    assetgrowthrank = ntile(assetgrowth, 5),
    acc.salesgrowthrank = ntile(acc.salesgrowth, 5),
    acc.earninggrowthrank = ntile(acc.earninggrowth, 5),
    acc.assetgrowthrank = ntile(acc.assetgrowth, 5)), keyby = date
    ][order(stkcd, date)] %>% na.omit()
sv(growthrank)

# Earning surprise ----
# ������Ԥ������У�eps��ȱʧֵ���ٵ�
# feps: ����ʦepsԤ���ƽ��ֵ
feps <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/����ʦԤ��/forcast.txt", encoding = "UTF-8", header = T)
setnames(feps, names(feps), tolower(names(feps)))
feps <- feps[, .(stkcd = sprintf("%06d", as.numeric(stkcd)), rptdt = as.Date(rptdt), fenddt = as.Date(fenddt), feps)
    ][, .(feps = median(feps, na.rm = T)), keyby = .(stkcd, year = year(fenddt))
    ][, ":="(feps = na.locf(feps, na.rm = F)), keyby = stkcd
    ] %>% na.omit()
# eps: ��˾ʵ�ʵ�eps
aeps <- fread("C:/Users/rossz/OneDrive/SNT/03-PeterLung/firm.char/����ʦԤ��/actual.txt", encoding = "UTF-8", header = T)
setnames(aeps, names(aeps), tolower(names(aeps)))
aeps <- aeps[, .(stkcd = sprintf("%06d", as.numeric(stkcd)), date = ymd(ddate), aeps = meps)
    ][month(date) == 12 # ֻѡ������eps��Ԥ��
    ][order(stkcd, date)
    ][, ":="(year = year(date))
    ] %>% na.omit() # ̫������aepsȱʧ�����޳�
# SUE: surpring earning
sue <- feps[aeps, on = .(stkcd, year), nomatch = 0
    ][, .(stkcd, date, sue = aeps - feps)]
CJ <- sue[, .(date = seq(min(date), as.Date("2017-10-01"), by = "day")), keyby = stkcd]
suerank <- sue[CJ, on = .(stkcd, date), nomatch = NA
    ][order(stkcd, date)
    ][, .(date, sue = na.locf(sue, na.rm = F)), keyby = stkcd
    ][, .(stkcd, suerank = ntile(sue, 5)), keyby = date
    ][order(stkcd, date)]
sv(suerank)

# firmchar: �����е�rank���ϲ� ----
ld(divrank)
ld(perank)
ld(sizerank)
ld(retrank)
ld(riskrank)
ld(profitrank)
ld(growthrank)
ld(suerank)

firmchar <- divrank[perank, on = .(stkcd, date), nomatch = 0
    ][sizerank, on = .(stkcd, date), nomatch = 0
    ][riskrank, on = .(stkcd, date), nomatch = 0
    ][growthrank, on = .(stkcd, date), nomatch = 0
    ][retrank, on = .(stkcd, date), nomatch = 0
    ][suerank, on = .(stkcd, date), nomatch = 0
    ][profitrank, on = .(stkcd, date), nomatch = 0
    ][order(stkcd, date)
    ] %>% unique()
sv(firmchar)

# ���� firmchar ���ݼ���һЩͳ��
#firmchar[, .N] # 1202113
#firmchar[, uniqueN(stkcd)] # 2793
#firmchar[, range(date)] # "2015-07-02" "2017-09-29"

# rb.char: ���� firm.char����� cube.rb���õ����˵�Ͷ�ʷ�� -----
ld(firmchar)
ld(p.cube.rb)
ld(f.sp.owner)

p.rb.char <- p.cube.rb[f.sp.owner, .(user.id, cube.symbol, stkcd = str_sub(stock.symbol, 3, 8), date, year = year(date), week = week(date), amt), on = .(cube.symbol), nomatch = 0
    ][, .(cube.symbol, year, week, amt = sum(amt)), keyby = .(user.id, date, stkcd) # ͬһ������ͬһ����ܽ���ͬһ����Ʊ��Σ����кϲ�
    ][firmchar, on = .(stkcd, date), nomatch = 0
    ][order(user.id, date, stkcd)
    ] %>% unique() %>% na.omit()
sv(p.rb.char)

# amt > 0 ֻ���� buy trade����������޽��ף���ôstrategy��ʹ��locf
p.rb.char.wk <- p.rb.char[amt > 0, lapply(.SD, weighted.mean, amt), keyby = .(user.id, cube.symbol, year, week), .SDcols = divrank:profitmarginrank
    ] %>% na.omit() 
sv(p.rb.char.wk)
