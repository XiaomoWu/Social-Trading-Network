# ���� f.stk.wrisk & cube.rb������hrs ----
ld(stk.wrisk)
ld(cube.rb)

# hrs: ��¼ÿ�����ÿһ�ܵ�risk 
# ���ĳ��û�����뽻�ף���ô��û�ж�Ӧ��¼
whrs <- cube.rb[order(cube.symbol, created.at)
    ][amt > 0, .(amt = sum(amt, na.rm = T)), keyby = .(cube.symbol, year, week, stock.symbol)
    ][stk.wrisk, on = .(stock.symbol = stkcd, year, week), nomatch =0
    ][, {amt.tot = sum(amt, na.rm = T);
        make_hrs <- function(x) {
            sum(amt[x >= 9], na.rm = T) / amt.tot
        };
        beta <- make_hrs(beta);
        skew <- make_hrs(skew);
        vol <- make_hrs(vol);
        ivol <- make_hrs(ivol);
        list(beta = beta, skew = skew, vol = vol, ivol = ivol)
        }, keyby = .(cube.symbol, year, week)]

# whrs.nwk: �� hrs �� user.wnwk.sp �ϲ� ----
ld(whrs)
ld(user.wnwk.sp)
whrs.nwk <- user.wnwk.sp[whrs, 
    .(from.cube.symbol, year, week, hrs.beta = beta, hrs.skew = skew, hrs.vol = vol, hrs.ivol = ivol, to.cube.symbol), 
    on = .(from.cube.symbol = cube.symbol, year, week), nomatch = 0
    ][!sapply(to.cube.symbol, is.null), .(to.cube.symbol = unlist(to.cube.symbol), hrs.beta, hrs.skew, hrs.vol, hrs.ivol), keyby = .(from.cube.symbol, year, week)
    ][hrs, .(from.cube.symbol, year, week, to.cube.symbol, hrs.beta, hrs.skew, hrs.vol, hrs.ivol, hrs.beta.nbr = beta, hrs.skew.nbr = skew, hrs.vol.nbr = vol, hrs.ivol.nbr = ivol),
    on = .(to.cube.symbol = cube.symbol, year, week), nomatch = 0
    ][order(from.cube.symbol, year, week)
    ][, .(hrs.beta, hrs.skew, hrs.vol, hrs.ivol, hrs.beta.nbr = mean(hrs.beta.nbr), hrs.skew.nbr = mean(hrs.skew.nbr), hrs.vol.nbr = mean(hrs.vol.nbr), hrs.ivol.nbr = mean(hrs.ivol.nbr)), keyby = .(from.cube.symbol, year, week)] %>% unique()

# �ع� ----
lm(hrs.ivol ~ hrs.ivol.nbr, data = whrs.nwk) %>% summary()

lm(I(diff(hrs.ivol)) ~ I(shift(hrs.ivol - hrs.ivol.nbr)[-1]), data = whrs.nwk) %>% summary()





