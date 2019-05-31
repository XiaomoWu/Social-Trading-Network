# ����ɸѡ������� cid��uid ----
ld(cid)
ld(uid)

# cube.info��������ͳ��----
# ����
if (!exists('cube.info')) ld(cube.info)
nrow(cube.info)
cube.info[, table(cube.type)]

# ����������
if (!exists('cube.info')) ld(cube.info)
cube.info[, uniqueN(owner.id)]
cube.info[, uniqueN(owner.id), by = cube.type]

# ������������ʱ��
if (!exists('cube.info')) ld(cube.info)
cube.info[, min(create.date), by = cube.type]

# ����
# ����������life�������������޳�life<0�����
if (!exists('cube.info')) ld(cube.info)
#sv(cube.info)
# life��������ͳ��
if (!exists('cube.info')) ld(cube.info)
cube.info[, mean(life)]
cube.info[, mean(life), by = cube.type]

# ��ע
if (!exists('cube.info')) ld(cube.info)
cube.info[, .(mean = mean(fans.count, na.rm = T), median = median(fans.count, na.rm = T))]
cube.info[, .(mean = mean(fans.count, na.rm = T), median = median(fans.count, na.rm = T)), by = cube.type]

# style
if (!exists('cube.info')) ld(cube.info)
cube.info[cube.type == 'ZH', table(style.name) / .N * 100]

# cube.rb��������ͳ��----
summ <- function(x) {
    c(as.list(summary(x)), list(sd = sd(x, na.rm = T)))
}
narrow <- function(x, low = 1, high = 1) {
    x <- x[!is.na(x)]
    x[x %between% c(quantile(x, low / 100), quantile(x, (100 - high) / 100))]
}
# �ܵ��ִ���
if (!exists("cube.rb")) ld(cube.rb)
cube.rb[cube.type == 'ZH', .(n = .N), keyby = cube.symbol][, summ(n)]
cube.rb[cube.type == 'SP', .(n = .N), keyby = cube.symbol][, summ(n)]
cube.rb[, .(n = .N), keyby = cube.symbol][, summ(n)]

# ƽ�����ִ���/���ʱ��
if (!exists("cube.rb")) ld(cube.rb)
if (!exists("cube.info")) ld(cube.info)
nrb <- cube.rb[, .(n = .N), keyby = cube.symbol]
cinfo <- cube.info[nrb, on = "cube.symbol", nomatch = 0]
cinfo[, ":="(freq = n / life, dfreq = life / n)] # dfreq��ʾ���ּ������
cinfo[, summ(dfreq)]
cinfo[, summ(dfreq), keyby = cube.type]
rm(cinfo)

# ƽ�����ַ���
if (!exists("cube.rb")) ld(cube.rb)
cube.rb[, narrow(abs(target.weight - prev.weight.adjusted)) %>% summ()]
cube.rb[, narrow(abs(target.weight - prev.weight.adjusted)) %>% summ(), keyby = cube.type]

# PLOT - ʵ�̵�����Ϊʱ��ֲ�
cube.rb[cube.type == 'SP'] %>%
    ggplot(aes(x = as.POSIXct(as.ITime(datetime)))) +
    geom_histogram(bins = 50) +
    xlab("") +
    ylab("Count") +
    theme_bw()

# user.info��������ͳ��----
if (!exists("r.user.info")) ld(r.user.info)
if (!exists("cube.info")) ld(cube.info)
user.info <- r.user.info[cube.info[order(owner.id, cube.type), .(cube.type = cube.type[1]), keyby = .(owner.id)], on = c(user.id = "owner.id"), nomatch = 0]
#sv(user.info)
# �������Ա�
user.info[, uniqueN(user.id)]
user.info[, uniqueN(user.id), keyby = gender]
user.info[, uniqueN(user.id), keyby = .(cube.type, gender)]
# �û�����ʡ��
user.info[, .N, by = .(province)][order(-N)]
t <- user.info[, .N, keyby = .(cube.type, province)][order(cube.type, - N)]
rm(t)
# ��֤�û���
user.info[verified | verified.realname, .N]
user.info[verified | verified.realname, .N, keyby = .(cube.type)]
# ƽ����ע/��˿/��ѡ��/���/������
col <- "status.count"
j <- parse(text = sprintf('.(mean = mean(%s, na.rm = T), median = median(%s, na.rm = T))', col, col))
user.info[, eval(j)]
user.info[, eval(j), keyby = cube.type]
rm(col, j)

# ret��������ͳ�� ----
summ <- function(x) {
    c(as.list(summary(x)), list(sd = sd(x, na.rm = T)))
}
# ���������������棨from cube.info��
if (!exists("f.cube.info")) ld(f.cube.info)
f.cube.info[, summ((net.value - 1) * 100)]
f.cube.info[, summ((net.value - 1) * 100), by = cube.type]
# �껯���棨from cube.info��
if (!exists("cube.info")) ld(cube.info)
cube.info[, summ(annual.ret)]
# ������һ�˹�ע����ϵ������棨from cube.info��
if (!exists("cube.info")) ld(cube.info)
cube.info[fans.count >= 5, summ((net.value - 1) * 100)]
cube.info[fans.count >= 5, summ((net.value - 1) * 100), keyby = cube.type]
# ������һ�˹�ע����ϵ��껯���棨from cube.info��
if (!exists("cube.info")) ld(cube.info)
cube.info[fans.count >= 5, summ(annual.ret)]

# PLOT - ��˿�������棨�ۼƷֲ���
if (!exists("cube.info")) ld(cube.info)
cum <- cube.info[cube.type == 'ZH'][order(annual.ret), .(annual.ret, fans.count, cumfans = cumsum(fans.count) / sum(fans.count) * 100)]
ggplot(cum, aes(x = annual.ret, y = cumfans)) +
    geom_line(size = 0.75) +
    xlim(c(-50, 400)) +
    xlab("Annualized Return in %") +
    ylab("Cumulative Distribution") +
    #theme_light() +
    theme_bw()
rm(cum)

# PLOT - �껯�����ʵķֲ�
if (!exists("cube.info")) ld(cube.info)
copy(cube.info)[cube.type == 'SP', annual.ret := ((net.value - 1) * 100)][,
    {   
        print(.BY)
        print(ggplot(.SD, aes(x = annual.ret)) +
            geom_histogram(bins = 300) +
            geom_density(kernel = 'gaussian') +
            xlim(c(-100, 100)) +
            ylab('Count') +
            xlab('Annulized Return in %') +
            theme_bw())
    },
    by = cube.type]
