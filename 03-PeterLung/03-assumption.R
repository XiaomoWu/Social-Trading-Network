# ����ű�������֤sending function��receiving function

SDATE <- as.Date("2016-07-01")
# ������֤sending function
# 1. ��table ----
ld(p.cube.wret, T)
ld(r.user.cmt) # ��ʱ 3.5 ����
ld(f.cu)
# cmt.n: ����ͳ�ơ�msg.n: ȫ��������msg.n.user���û��������ų����Ҹոա���
cmt.n <- r.user.cmt[date >= SDATE, .(msg.n = .N, msg.n.user = .N - sum(str_sub(text, 1, 3) == "�Ҹո�")), keyby = .(user.id, year = year(date), week = week(date))]
sv(cmt.n)

# ��cmt.n��������ϲ���ֻ���� SP
send <- cmt.n[p.cube.wret[, .(cube.symbol, year, week, wret, date)][f.cu, on = .(cube.symbol), nomatch = 0],
    on = .(user.id, year, week)
    ][order(user.id, year, week, cube.symbol)
    ][, ":="(msg.n = fillna(msg.n), msg.n.user = fillna(msg.n.user))] # ��Щweekû��msg���� 0 ���

# ÿ�ܰ���ret��quintle������msg.n�Ĺ�ϵ
ret.rank <- send[cube.type == "SP", .(msg.n = mean(msg.n), msg.n.user = mean(msg.n.user), wret = mean(wret), wret.max = max(wret)), keyby = .(user.id, year, week)
    ][, .(user.id, wret.rank = ntile(wret, 5), wret.max.rank = ntile(wret.max, 5), msg.n, msg.n.user), keyby = .(year, week) # ��ͬһ��user.id��cube�����ϵ�һ��
    ]
# ����msg.n������
ret.rank[, .(msg.n = sum(msg.n > 1, na.rm = T) / .N, msg.n.user = sum(msg.n.user > 1, na.rm = T) / .N), keyby = .(wret.max.rank)]
# ����msg.n�ĸ���
ret.rank[, .(msg.n = mean(msg.n, na.rm = T), msg.n.user = mean(msg.n.user, na.rm = T)), keyby = .(wret.max.rank)]

# 2. ��regression ----
ld(f.sp.owner)
ld(f.user.nwk)
ld(f.ywd)
# send2������send�ļ�ǿ�棬���������� ret �� msg ���⣬�������� nbr ����Ϣ
# send2 ֻ���� SP 
send2 <- f.user.nwk[, .(nbr = unlist(nbr)), keyby = .(user.id, year, week)
    ][send[, .(cube.symbol, year, week, wret, msg.n, msg.n.user)], on = c(nbr = "cube.symbol", "year", "week"), nomatch = 0
    ][, .(wret.nbr = mean(wret), wret.max.nbr = max(wret), msg.n.nbr = mean(msg.n), msg.n.user.nbr = mean(msg.n.user)), keyby = .(user.id, year, week) # ���� peer effect
    ][f.sp.owner, on = .(user.id), nomatch = 0
    ][send[, .(cube.symbol, year, week, wret, msg.n, msg.n.user)], on = .(cube.symbol, year, week), nomatch = 0
    ][, ":="(wret.gap.nbr = wret.nbr - wret)
    ][f.ywd, on = .(year, week), nomatch = 0]
sv(send2)

# run regression
file <- "C:/Users/rossz/OneDrive/SNT/03-PeterLung/reg.html"
stars <- c(0.01, 0.05, 0.1)

fit <- plm(msg.n.user ~ wret + I(wret^2) + wret.nbr + msg.n.user.nbr, data = send2, model = "within", effect = "twoways", index = c("cube.symbol", "date"))
summary(fit)
screenreg(fit)
htmlreg(fit, stars = stars, file = file, digits = 4)


# receiving function ----
ld(p.cube.rb)
ld(rb.char.wk)
ld(send2)
ld(p.cen)
# receive2 �� send2 �Ľ������������� (1) trading freq(tf) ��(2) rb.char , (3) cen+degree
# receive2 ֻ���� SP
receive <- p.cube.rb[, .(tf = .N, tf.buy = sum(amt > 0)), keyby = .(cube.symbol, year = year(date), week = week(date))
    ][send2, on = .(cube.symbol, year, week)
    ][order(user.id, year, week)
    ][, ":="(tf = fillna(tf), tf.buy = fillna(tf.buy))
    ]
#receive2 <- rb.char.wk[receive, on = .(cube.symbol, user.id, year, week)
    #][, (5:26) := lapply(.SD, na.locf, F), keyby = .(user.id, cube.symbol), .SDcols = divrank:profitmarginrank # rb.char.wk��һ��ÿ�ܶ��У���Ϊ�м��ܿ���û�����뽻�ף�������� locf ���
    #][order(user.id, year, week)
    #][, ":="(user.id = as.character(user.id))
    #][p.cen, on = .(user.id), nomatch = 0
    #] %>% na.omit()
sv(receive2)
 

# run regression
file <- "C:/Users/rossz/OneDrive/SNT/03-PeterLung/reg.html"
stars <- c(0.01, 0.05, 0.1)

# ����individual effects����fixed effects capture
fit <- plm(tf.buy ~ I((wret.nbr - wret) ^ 2) + I(wret.nbr - wret) + I(as.factor(date)), data = receive2, index = c("cube.symbol", "date")) # ��time-effect��as.factor(date)��ʾ��Ч���ܺã�R�ܴﵽ0.03��

# ����fixed effects���ֶ����� cen��degree
fit <- lm(tf.buy ~ I((wret.nbr - wret) ^ 2) + I(wret.nbr - wret) + cen.scale + d.out + I(as.factor(date)), data = receive2) # ��time-effect��as.factor(date)��ʾ��Ч���ܺã�R�ܴﵽ0.03��

htmlreg(fit, stars = stars, file = file, digits = 4)