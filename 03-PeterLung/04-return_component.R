# ����ű��������� A��P��return�Ƿ��в�ͬ��panelty��sigma�ȣ�
# ������ű��У�AP�������������������з����
ld(ap.all)
ld(p.cube.wret)
ld(p.wret.mkt)

ret.comp <- p.cube.wret[, .(cube.symbol, year, week, wret)
    ][p.wret.mkt, on = .(year, week), nomatch = 0
    ][ap.all, on = .(cube.symbol), nomatch = 0]

fit_ret_comp <- function(data) {
    lm(wret ~ wret.mkt, data = data) # ���ﲻ����fixed����Ϊһ��fixedÿ����϶�������Լ���alpha
}
fit.a <- fit_ret_comp(ret.comp[is.a == T])
fit.p <- fit_ret_comp(ret.comp[is.a == F])

# ����������ܺã���ģ��Ԥ��һ����
fit.a; sd(fit.a$residuals)
fit.p; sd(fit.p$residuals)