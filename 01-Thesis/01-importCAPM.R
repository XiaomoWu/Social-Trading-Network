# ����������� ----
# ֱ�Ӷ����ⲿ trd.dalyr.Rdata �ļ� - 2017-09-30�����ٴ�MySQL�ж�ȡ��
ld(trd.dalyr)
r.dstk <- trd.dalyr[trddt >= as.Date("2014-01-01"), .(stkcd = stkcd, date = ymd(trddt), vol = dnshrtrd, amt = dnvaltrd, mv = dsmvosd, dret = dretnd, adjprc = adjprcnd, mkttype = markettype)] # mv: market value, mkttype: 1=�Ϻ�A��2=�Ϻ�B��4=����A��8=����B,  16=��ҵ��
setkey(r.dstk, stkcd, date)
sv(r.dstk)

# ���������� ----
ld(sdi.thrfacday)
r.d3f <- sdi.thrfacday[markettypeid == "P9709", .(date = trddt, rm = riskpremium1, smb = smb1, hml = hml1)]
sv(r.d3f)