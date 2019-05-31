# ����xq_user_stock ----
# ���� mongodb ���������´��룬����flatten�������������� r_user_stock
db.getCollection('xq_user_stock_updt').aggregate([
{"$project":{"count":1, "isPublic":1, "stocks":1, "user_id":1}},
{"$unwind":"$stocks"},
{"$project":{"_id":0, "user_id":"$user_id", "count":1, "isPublic":1, "code":"$stocks.code", "comment":{"$ifNull":["$stocks.comment", ""]}, 
"sellPrice":"$stocks.sellPrice", "buyPrice":"$stocks.buyPrice", "portfolioIds":"$stocks.portfolioIds",
"createAt":"$stocks.createAt", "targetPercent":"$stocks.targetPercent", "isNotice":"$stocks.isNotice",
"stockName":{"$ifNull":["$stocks.stockName",""]}, 
"exchange":{"$ifNull":["$stocks.exchange",""]},
"stockType":{"$ifNull":["$stocks.stockType",""]}}},
{"$out":"r_user_stock"}
], {"allowDiskUse":true})

# Ȼ���ٰ�flatten������ݼ� (r_user_stock) ����R
library(mongolite)
conn <- mongo(collection = 'xq_user_stock', db = 'XQ-1806', url = "mongodb://localhost:27018")
iter <- conn$iterate(field = '{"_id":0, "count":1, "isPublic":1, "stocks":1, "user_id":1}')
r.user.stock.1803 <- data.table()



system.time({
    while (!is.null(res <- iter$batch(size = 1e6))) {
        chunk <- rbindlist(res, use.names = T, fill = T)
        r.user.stock.1806 <- rbindlist(list(r.user.stock.1806, chunk), use.names = T, fill = T)
    }
}) # 7min@1e6 (batch.size = 1e6 �� 1e7Ҫ�죬��Ϊ1e7��ű��ڴ�)



res <- iter$batch(size = 1e5)