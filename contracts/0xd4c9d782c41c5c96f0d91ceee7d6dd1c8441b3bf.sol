/*! gbcoin.sol | (c) 2017 Develop by BelovITLab, autor my.life.cookie | License: MIT */

/*

    Russian

    Ð§ÑÐ¾ ÑÐ°ÐºÐ¾Ðµ GB Systems:
    Ð­ÑÐ¾ Geo Blockchain ÑÐ¸ÑÑÐµÐ¼Ð°, ÐºÐ¾ÑÐ¾ÑÐ°Ñ Ð½Ðµ Ð¿ÑÐ¸Ð²ÑÐ·ÑÐ²Ð°ÐµÑÑÑ Ð½Ð¸ Ðº Ð¾Ð´Ð½Ð¾Ð¹ ÑÑÑÐ°Ð½Ðµ Ð¸ Ð±Ð°Ð½ÐºÐ°Ð¼. Ð£ Ð½Ð°Ñ ÐµÑÑÑ ÑÐ²Ð¾Ð¹ 
    Ð¿ÑÐ¾ÑÐµÑÑÐ¸Ð½Ð³Ð¾Ð²ÑÐ¹ ÑÐµÐ½ÑÑ, ÑÐºÐ²Ð°Ð¹ÑÐ¸Ð½Ð³ Ð¸ Ð¿Ð»Ð°ÑÐµÐ¶Ð½Ð°Ñ ÑÐ¸ÑÑÐµÐ¼Ð° GBPay - Ð°Ð½Ð°Ð»Ð¾Ð³ Visa, MasterCard, UnionPay. 
    ÐÑÐµ ÑÑÐ°Ð½Ð·Ð°ÐºÑÐ¸Ð¸ ÐºÐ¾ÑÐ¾ÑÑÐµ Ð±ÑÐ´ÑÑ Ð¿ÑÐ¾ÑÐ¾Ð´Ð¸ÑÑ Ð²Ð½ÑÑÑÐ¸ ÑÐ¸ÑÑÐµÐ¼Ñ Ð¸ Ð±Ð°Ð½ÐºÐ¾Ð² Ð¿Ð°ÑÑÐ½ÐµÑÐ¾Ð² Ð¼Ð¾Ð¼ÐµÐ½ÑÐ°Ð»ÑÐ½Ð¾. Ð¢Ð°Ðº Ð¶Ðµ, 
    Ð¿Ð¾Ð´ÐºÐ»ÑÑÐ°ÑÑÐ¸ÐµÑÑ ÐºÐ¾Ð¼Ð¿Ð°Ð½Ð¸Ð¸ Ð¿Ð°ÑÑÐ½ÐµÑÐ¾Ð² Ð¸ Ð±Ð°Ð½ÐºÐ¸, Ð¸Ð¼ÐµÑÑ Ð²Ð¾Ð·Ð¼Ð¾Ð¶Ð½Ð¾ÑÑÑ Ð¸ÑÐ¿Ð¾Ð»ÑÐ·Ð¾Ð²Ð°ÑÑ Ð²ÑÑ ÑÐ¸ÑÑÐµÐ¼Ñ Ð´Ð»Ñ ÑÐ²Ð¾ÐµÐ³Ð¾ 
    Ð±Ð¸Ð·Ð½ÐµÑÐ°, Ð¿ÑÑÐµÐ¼ Ð¸Ð½ÑÐµÐ³ÑÐ°ÑÐ¸Ð¸ API ÐºÐ¾Ð´Ð° Ð¸ Ð¸ÑÐ¿Ð¾Ð»ÑÐ·Ð¾Ð²Ð°ÑÑ Ð²ÑÐµ Ð²Ð¾Ð·Ð¼Ð¾Ð¶Ð½Ð¾ÑÑÐ¸ Ð½Ð°ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ñ Ð´Ð»Ñ ÑÐ²Ð¾Ð¸Ñ ÐºÐ»Ð¸ÐµÐ½ÑÐ¾Ð². 
    ÐÐ°Ð¶Ð´Ð¾Ð¼Ñ Ð¿Ð°ÑÑÐ½ÐµÑÑ Ð²ÑÐ³Ð¾Ð´Ð½Ð¾ ÑÐ¾ÑÑÑÐ´Ð½Ð¸ÑÐ°ÑÑ Ñ Ð½Ð°ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ð¾Ð¹, ÑÑÐ¾ Ð¿Ð¾Ð·Ð²Ð¾Ð»Ð¸ÑÑ ÑÐ²ÐµÐ»Ð¸ÑÐ¸ÑÑ ÐºÐ¾Ð»Ð¸ÑÐµÑÑÐ²Ð¾ ÐºÐ»Ð¸ÐµÐ½ÑÐ¾Ð² 
    Ð²Ð¾ Ð²ÑÐµÐ¼ Ð¼Ð¸ÑÐµ. Ð Ð½Ð°ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ðµ ÑÐºÐ¾ÑÐ¾ Ð±ÑÐ´ÐµÑ ÑÐ¾Ð»Ð¾Ð´Ð½ÑÐ¹ ÐºÐ¾ÑÐµÐ»ÐµÐº GB Wallet, Ð³Ð´Ðµ Ð¼Ð¾Ð¶Ð½Ð¾ ÑÑÐ°Ð½Ð¸ÑÑ ÐºÑÐ¸Ð¿ÑÐ¾Ð²Ð°Ð»ÑÑÑ 
    Ð¸ Ð½Ð°ÑÐ¸Ð¾Ð½Ð°Ð»ÑÐ½ÑÑ Ð²Ð°Ð»ÑÑÑ Ð»ÑÐ±Ð¾Ð¹ ÑÑÑÐ°Ð½Ñ. ÐÐ¾Ð¼Ð¿Ð°Ð½Ð¸Ñ GB Network Ð¿Ð¾Ð·Ð²Ð¾Ð»Ð¸Ñ ÐºÐ°Ð¶Ð´Ð¾Ð¼Ñ ÐºÐ»Ð¸ÐµÐ½ÑÑ Ð¿ÑÐ¸Ð¾Ð±ÑÐµÑÑÐ¸ Ð²Ð¸ÑÑÑÐ°Ð»ÑÐ½ÑÐ¹ 
    ÑÑÐµÑ, Ð³Ð´Ðµ Ð¼Ð¾Ð¶Ð½Ð¾ ÑÑÐ°Ð½Ð¸ÑÑ ÑÑÐµÐ´ÑÑÐ²Ð°, Ð¸ ÑÐ¾Ð²ÐµÑÑÐ°ÑÑ Ð¿Ð¾ÐºÑÐ¿ÐºÑ Ð¿ÑÑÐµÐ¼ Ð¿ÑÐ¸Ð»Ð¾Ð¶ÐµÐ½Ð¸Ñ NFC, Ð¾Ð´Ð½Ð¸Ð¼ ÐºÐ°ÑÐ°Ð½Ð¸ÐµÐ¼ Ðº ÐÐ¾ÑÑ 
    Ð¢ÐµÑÐ¼Ð¸Ð½Ð°Ð»Ñ, Ð° ÑÐ°ÐºÐ¶Ðµ Ð¿Ð¾ÐºÑÐ¿Ð°ÑÑ Ð¸ Ð¾Ð¿Ð»Ð°ÑÐ¸Ð²Ð°ÑÑ ÑÑÐ»ÑÐ³Ð¸ Ð¸ ÑÐ¾Ð²Ð°ÑÑ ÑÐµÑÐµÐ· Ð¾Ð½Ð»Ð°Ð¹Ð½ ÑÐ¸ÑÑÐµÐ¼Ñ. Ð¢Ð°Ðº Ð¶Ðµ ÐºÐ¾Ð¼Ð¿Ð°Ð½Ð¸Ñ Ð´Ð°ÐµÑ 
    Ð²Ð¾Ð·Ð¼Ð¾Ð¶Ð½Ð¾ÑÑÑ Ð·Ð°ÑÐ°Ð±Ð°ÑÑÐ²Ð°ÑÑ Ð½Ð° Ð¿Ð°ÑÑÐ½ÐµÑÑÐºÐ¾Ð¹ Ð¿ÑÐ¾Ð³ÑÐ°Ð¼Ð¼Ðµ. ÐÑ Ð½Ðµ Ð·Ð°Ð±ÑÐ»Ð¸ Ð¸ Ð¾ Ð±Ð»Ð°Ð³Ð¾ÑÐ²Ð¾ÑÐ¸ÑÐµÐ»ÑÐ½Ð¾Ð¼ ÑÐ¾Ð½Ð´Ðµ, ÐºÐ¾ÑÐ¾ÑÑÐ¹ 
    Ð±ÑÐ´ÐµÑ Ð¼ÐµÐ¶ÑÐ´Ð½Ð°ÑÐ¾Ð´Ð½ÑÐ¹ Ð¸ Ð½Ðµ Ð¿ÑÐ¸Ð²ÑÐ·ÑÐ²Ð°ÑÑÑÑ Ðº Ð¾Ð´Ð½Ð¾Ð¹ ÑÑÑÐ°Ð½Ðµ. Ð§Ð°ÑÑÑ ÑÑÐµÐ´ÑÑÐ² Ð¾Ñ Ð½Ð°ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ñ Ð±ÑÐ´ÐµÑ Ð¿Ð¾ÑÑÑÐ¿Ð°ÑÑ 
    Ð² ÑÑÐ¾Ñ ÑÐ¾Ð½Ð´.
    
    ÐÐ°Ð½ÐºÐ°Ð¼ Ð¿Ð°ÑÑÐ½ÐµÑÐ°Ð¼ ÑÐ°Ð·ÑÐµÑÐ°ÐµÑÑÑ Ð¿Ð¾ Ð¼Ð¸Ð¼Ð¾ Ð½Ð°ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ñ, Ð¸Ð¼Ð¸ÑÐ¸ÑÐ¾Ð²Ð°ÑÑ Ð¿Ð»Ð°ÑÑÐ¸ÐºÐ¾Ð²ÑÐµ ÐºÐ°ÑÑÑ Ð´Ð»Ñ ÑÐ²Ð¾Ð¸Ñ Ð¸ Ð½Ð°ÑÐ¸Ñ 
    ÐºÐ»Ð¸ÐµÐ½ÑÐ¾Ð²  Ð²ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ñ, Ð² Ð½Ð°ÑÐ¸Ð¾Ð½Ð°Ð»ÑÐ½Ð¾Ð¹ Ð²Ð°Ð»ÑÑÐµ, Ñ Ð¿ÑÐ¸Ð¼ÐµÐ½ÐµÐ½Ð¸ÐµÐ¼ Ð½Ð°ÑÐµÐ¹ Ð¿Ð»Ð°ÑÐµÐ¶Ð½Ð¾Ð¹ ÑÐ¸ÑÑÐµÐ¼Ð¾Ð¹ Ñ Ð½Ð°ÑÐ¸Ð¼ Ð»Ð¾Ð³Ð¾ÑÐ¸Ð¿Ð¾Ð¼ 
    GBPay, Ð¸ Ñ Ð¸ÑÐ¿Ð¾Ð»ÑÐ·Ð¾Ð²Ð°Ð½Ð¸ÐµÐ¼  Ð½Ð°ÑÐµÐ¹ Ð¿Ð»Ð°ÑÑÐ¾ÑÐ¼Ñ Blockchain, ÐºÑÐ´Ð° Ð²ÑÐ¾Ð´Ð¸Ñ ÑÐºÐ²Ð°Ð¹ÑÐ¸Ð½Ð³, Ð¿ÑÐ¾ÑÐµÑÑÐ¸Ð½Ð³Ð¾Ð²ÑÐ¹ ÑÐµÐ½ÑÑ Ð¸ 
    Ð¿Ð»Ð°ÑÐµÐ¶Ð½Ð°Ñ ÑÐ¸ÑÑÐµÐ¼Ð°, Ð²ÑÐµ ÑÑÐ¾ Ð·Ð° 1,2%. ÐÑÐ°Ð½Ð¸Ñ Ð¼ÐµÐ¶Ð´Ñ ÑÑÑÐ°Ð½Ð°Ð¼Ð¸ Ð² Ð½Ð°ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ðµ Ð½ÐµÑ, ÑÑÐ¾ Ð¿Ð¾Ð·Ð²Ð¾Ð»ÑÐµÑ ÑÐ¾Ð²ÐµÑÑÐ°ÑÑ 
    Ð¿Ð»Ð°ÑÐµÐ¶Ð¸ Ð¸ Ð¿ÐµÑÐµÐ²Ð¾Ð´Ñ Ð·Ð° ÑÐµÐºÑÐ½Ð´Ñ Ð² Ð»ÑÐ±Ð¾Ñ ÑÐ¾ÑÐºÑ Ð·ÐµÐ¼Ð½Ð¾Ð³Ð¾ ÑÐ°ÑÐ°. ÐÐ»Ñ ÑÐ°Ð±Ð¾ÑÑ Ð² ÑÐ¸ÑÑÐµÐ¼Ðµ, Ð¼Ñ ÑÐ¾Ð·Ð´Ð°Ð»Ð¸ ÑÐ¾ÐºÐµÐ½ GBCoin, 
    ÐºÐ¾ÑÐ¾ÑÑÐ¹ Ð±ÑÐ´ÐµÑ Ð¾ÑÐ²ÐµÑÐ°ÑÑ Ð·Ð° Ð²ÐµÑÑ ÑÑÐ½ÐºÑÐ¸Ð¾Ð½Ð°Ð» ÑÐ¸Ð½Ð°Ð½ÑÐ¾Ð²Ð¾Ð¹ ÑÐ¸ÑÑÐµÐ¼Ñ GB Systems, ÐºÐ°Ðº Ð²Ð½ÑÑÑÐµÐ½Ð½ÑÑ Ð¼ÐµÐ¶Ð´ÑÐ½Ð°ÑÐ¾Ð´Ð½Ð°Ñ 
    ÑÑÐ°Ð½Ð·Ð°ÐºÑÐ¸Ð¾Ð½Ð½Ð°Ñ Ð²Ð°Ð»ÑÑÐ° ÑÐ¸ÑÑÐµÐ¼Ñ, ÐºÐ¾ÑÐ¾ÑÐ¾Ð¹ Ð±ÑÐ´ÑÑ Ð¿ÑÐ¸Ð²ÑÐ·Ð°Ð½Ñ Ð²ÑÐµ Ð½Ð°ÑÐ¸ ÐºÐ¾Ð¼Ð¿Ð°Ð½Ð¸Ð¸ Ð¸ Ð±Ð°Ð½ÐºÐ¸. 
    
    Ð Ð½Ð°ÑÐµÐ¹ ÑÐ¸ÑÑÐµÐ¼Ðµ GB Systems Ð¿Ð¾Ð´ÐºÐ»ÑÑÐµÐ½Ñ: Grande Bank, Grande Finance, GB Network, GBMarkets, GB Wallet, 
    Charity Foundation, GBPay.
    
    ÐÑ ÑÐ°Ðº Ð¶Ðµ Ð±ÑÐ´ÐµÐ¼ Ð¿ÑÐµÐ´Ð¾ÑÑÐ°Ð²Ð»ÑÑÑ Ð¿Ð¾ÑÑÐµÐ±Ð¸ÑÐµÐ»ÑÑÐºÐ¸Ðµ ÐºÑÐµÐ´Ð¸ÑÑ, Ð°Ð²ÑÐ¾ÐºÑÐµÐ´Ð¸ÑÐ¾Ð²Ð°Ð½Ð¸Ðµ, Ð¸Ð¿Ð¾ÑÐµÑÐ½Ð¾Ðµ ÐºÑÐµÐ´Ð¸ÑÐ¾Ð²Ð°Ð½Ð¸Ðµ, 
    Ð¿Ð¾Ð´ Ð¼Ð¸Ð½Ð¸Ð¼Ð°Ð»ÑÐ½ÑÐµ Ð¿ÑÐ¾ÑÐµÐ½ÑÑ, Ð¾ÑÐºÑÑÐ²Ð°ÐµÑÑ Ð´ÐµÐ¿Ð¾Ð·Ð¸ÑÐ½ÑÐµ Ð¸ Ð¸Ð½Ð²ÐµÑÑÐ¸ÑÐ¸Ð¾Ð½Ð½ÑÐµ Ð²ÐºÐ»Ð°Ð´Ñ, Ð²ÐºÐ»Ð°Ð´Ñ Ð½Ð° Ð´Ð¾Ð²ÐµÑÐ¸ÑÐµÐ»ÑÐ½Ð¾Ðµ 
    ÑÐ¿ÑÐ°Ð²Ð»ÐµÐ½Ð¸Ðµ, ÑÑÑÐ°ÑÐ¾Ð²Ð°Ð½Ð¸Ðµ Ñ Ð±Ð¾Ð»ÑÑÐ¸Ð¼Ð¸ Ð²Ð¾Ð·Ð¼Ð¾Ð¶Ð½Ð¾ÑÑÑÐ¼Ð¸, Ð¾Ð±Ð¼ÐµÐ½Ð½Ð¸Ðº Ð²Ð°Ð»ÑÑ, Ð¿Ð»Ð°ÑÐµÐ¶Ð½Ð°Ñ ÑÐ¸ÑÑÐµÐ¼Ð°, ÑÐ°Ðº Ð¶Ðµ Ð¼Ð¾Ð¶Ð½Ð¾ 
    Ð±ÑÐ´ÐµÑ  Ð¾Ð¿Ð»Ð°ÑÐ¸Ð²Ð°ÑÑ Ð½Ð°ÑÐµÐ¹ ÐºÑÐ¸Ð¿ÑÐ¾Ð²Ð°Ð»ÑÑÐ¾Ð¹ GBCoin ÑÑÐ»ÑÐ³Ð¸ ÑÐ°ÐºÑÐ¸ Ð² ÑÐ°Ð·Ð½ÑÑ ÑÑÑÐ°Ð½Ð°Ñ, Ð¾Ð¿Ð»Ð°ÑÐ¸Ð²Ð°ÑÑ Ð·Ð° 
    ÑÑÑÐ¸ÑÑÐ¸ÑÐµÑÐºÐ¸Ðµ Ð¿ÑÑÐµÐ²ÐºÐ¸ Ñ ÑÑÑÐ¾Ð¿ÐµÑÐ°ÑÐ¾ÑÐ¾Ð²,  ÐÐ¾ ÑÐ¸ÑÑÐµÐ¼Ðµ Ð»Ð¾ÑÐ»ÑÐ½Ð¾ÑÑÐ¸ Ð¸Ð¼ÐµÑÑ Ð²Ð¾Ð·Ð¼Ð¾Ð¶Ð½Ð¾ÑÑÑ Ð¿Ð¾Ð»ÑÑÐ°ÑÑ ÑÐºÐ¸Ð´ÐºÐ¸ 
    Ð¸ cash back Ð² Ð¿ÑÐ¾Ð´ÑÐºÑÐ¾Ð²ÑÑ Ð¼Ð°Ð³Ð°Ð·Ð¸Ð½Ð°Ñ Ð¿Ð°ÑÑÐ½ÐµÑÐ¾Ð² Ð¸ Ð¼Ð½Ð¾Ð³Ð¾Ðµ Ð´ÑÑÐ³Ð¾Ðµ. 
    
    Ð¡ Ð½Ð°Ð¼Ð¸ Ð²Ñ Ð±ÑÐ´ÐµÑÐµ Ð¸Ð¼ÐµÑÑ Ð²ÑÐµ Ð² Ð¾Ð´Ð½Ð¾Ð¹ ÑÐ¸ÑÑÐµÐ¼Ðµ Ð¸ Ð½Ðµ Ð½ÑÐ¶Ð½Ð¾ Ð±ÑÐ´ÐµÑ Ð¾Ð±ÑÐ°ÑÐ°ÑÑÑÑ Ð² ÑÑÐ¾ÑÐ¾Ð½Ð½Ð¸Ðµ ÑÑÑÑÐºÑÑÑÑ. 
    Ð£Ð´Ð¾Ð±ÑÑÐ²Ð¾ Ð¸ ÐÐ°ÑÐµÑÑÐ²Ð¾ Ð´Ð»Ñ Ð²ÑÐµÑ ÐºÐ»Ð¸ÐµÐ½ÑÐ¾Ð².



    English

    What is GB Systems:
    It is Geo Blockchain system which does not become attached to one country and banks. 
    We have the processing center, acquiring and GBPay payment provider - this analog  Visa, MasterCard, 
    UnionPay. All transactions which will take place in system and banks of partners instantly. Also, 
    the connected partner companies and banks, have an opportunity to use all system for the business, 
    by integration of an API code and to use all opportunities of our system for the clients. It is 
    profitable to each partner to cooperate with our system what to allow to increase the number of 
    clients around the world. In our system there will be soon a cold purse of GB Wallet where it is 
    possible to keep cryptocurrency and national currency of any country. The GB Network company will 
    allow each client to purchase the virtual account where it is possible to store means and to make 
    purchase by the application NFC, one contact to the Post to the Terminal and also to buy and pay 
    services and goods through online system. Also the company gives the chance to earn on the partner 
    program. We did not forget also about charity foundation which will be mezhudnarodny and not to 
    become attached to one country. A part of means from our system will come to this fund. To partners 
    it is allowed to banks on by our system, to imitate plastic cards for the and our clients of all 
    system, in national currency, using our payment service provider with our GBPay logo, and with use 
    of our Blockchain platform where acquiring, a processing center and a payment service provider, 
    all this for 1,2% enters. There are no borders between the countries in our system that allows 
    to make payments and transfers for second in any a globe point. For work in system, we created 
    a token of GBCoin which will be responsible for all functionality of the GB Systems financial 
    system as internal world transactional currency of system which will attach all our companies 
    and banks.

    Our system is already connected Grande Bank, Grande Finance, GB Network, GBMarkets, GB Wallet, 
    Charity Foundation, GBPay.

*/

pragma solidity 0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() { require(!paused); _; }
    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }
    
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract ERC20 {
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function allowance(address owner, address spender) constant returns (uint256);
    function approve(address spender, uint256 value) returns (bool);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns(bool success) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) returns(bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) returns(bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) returns(bool success) {
        uint oldValue = allowed[msg.sender][_spender];

        if(_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }
}

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burn(burner, _value);
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    uint public MAX_SUPPLY;

    modifier canMint() { require(!mintingFinished); _; }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool success) {
        require(totalSupply.add(_amount) <= MAX_SUPPLY);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);

        return true;
    }

    function finishMinting() onlyOwner public returns(bool success) {
        mintingFinished = true;

        MintFinished();

        return true;
    }
}

/*
    ICO GBCoin
    - Ð­Ð¼Ð¸ÑÑÐ¸Ñ ÑÐ¾ÐºÐµÐ½Ð¾Ð² Ð¾Ð³ÑÐ°Ð½Ð¸ÑÐµÐ½Ð° (Ð²ÑÐµÐ³Ð¾ 40 000 000 ÑÐ¾ÐºÐµÐ½Ð¾Ð², ÑÐ¾ÐºÐµÐ½Ñ Ð²ÑÐ¿ÑÑÐºÐ°ÑÑÑÑ Ð²Ð¾ Ð²ÑÐµÐ¼Ñ Crowdsale)
    - Ð¦ÐµÐ½Ð° ÑÐ¾ÐºÐµÐ½Ð° Ð²Ð¾ Ð²ÑÐµÐ¼Ñ ÑÑÐ°ÑÑÐ°: 1 ETH = 20 ÑÐ¾ÐºÐµÐ½Ð¾Ð² (1 Eth (~500$) / 20 = ~25$) (ÑÐµÐ½Ñ Ð¼Ð¾Ð¶Ð½Ð¾ Ð¸Ð·Ð¼ÐµÐ½Ð¸ÑÑ Ð²Ð¾ Ð²ÑÐµÐ¼Ñ ICO)
    - ÐÐ¸Ð½Ð¸Ð¼Ð°Ð»ÑÐ½Ð°Ñ Ð¸ Ð¼Ð°ÐºÑÐ¸Ð¼Ð°Ð»ÑÐ½Ð°Ñ ÑÑÐ¼Ð¼Ð° Ð¿Ð¾ÐºÑÐ¿ÐºÐ¸: 1 ETH Ð¸ 10 000 ETH
    - Ð¢Ð¾ÐºÐµÐ½Ð¾Ð² Ð½Ð° Ð¿ÑÐ¾Ð´Ð°Ð¶Ñ 20 000 000 (50%)
    - 20 000 000 (50%) ÑÐ¾ÐºÐµÐ½Ð¾Ð² Ð¿ÐµÑÐµÐ´Ð°ÐµÑÑÑ Ð±ÐµÐ½ÐµÑÐ¸ÑÐ¸Ð°ÑÑ Ð²Ð¾ Ð²ÑÐµÐ¼Ñ ÑÐ¾Ð·Ð´Ð°Ð½Ð¸Ñ ÑÐ¾ÐºÐµÐ½Ð°
    - Ð¡ÑÐµÐ´ÑÑÐ²Ð° Ð¾Ñ Ð¿Ð¾ÐºÑÐ¿ÐºÐ¸ ÑÐ¾ÐºÐµÐ½Ð¾Ð² Ð¿ÐµÑÐµÐ´Ð°ÑÑÑÑ Ð±ÐµÐ½ÐµÑÐ¸ÑÐ¸Ð°ÑÑ
    - ÐÐ°ÐºÑÑÑÐ¸Ðµ Crowdsale Ð¿ÑÐ¾Ð¸ÑÑÐ¾Ð´Ð¸Ñ Ñ Ð¿Ð¾Ð¼Ð¾ÑÑÑ ÑÑÐ½ÐºÑÐ¸Ð¸ `withdraw()`:Ð½ÐµÑÐ°ÑÐºÑÐ¿Ð»ÐµÐ½Ð½ÑÐµ ÑÐ¾ÐºÐµÐ½Ñ Ð¸ ÑÐ¿ÑÐ°Ð²Ð»ÐµÐ½Ð¸Ðµ ÑÐ¾ÐºÐµÐ½Ð¾Ð¼ Ð¿ÐµÑÐµÐ´Ð°ÑÑÑÑ Ð±ÐµÐ½ÐµÑÐ¸ÑÐ¸Ð°ÑÑ, Ð²ÑÐ¿ÑÑÐº ÑÐ¾ÐºÐµÐ½Ð¾Ð² Ð·Ð°ÐºÑÑÐ²Ð°ÐµÑÑÑ
    - ÐÐ·Ð¼ÐµÐ½Ð¸Ðµ ÑÐµÐ½Ñ ÑÐ¾ÐºÐµÐ½Ð° Ð¿ÑÐ¾Ð¸ÑÑÐ¾Ð´ÐµÑ ÑÑÐ½ÐºÑÐ¸ÐµÐ¹ `setTokenPrice(_value)`, Ð³Ð´Ðµ `_value` - ÐºÐ¾Ð»-Ð²Ð¾ ÑÐ¾ÐºÐµÐ½Ð¾Ð² Ð¿Ð¾ÐºÑÐ¼Ð°ÐµÐ¼Ð¾Ðµ Ð·Ð° 1 Ether, ÑÐ¼ÐµÐ½Ð° ÑÑÐ¾Ð¸Ð¼Ð¾ÑÑÐ¸ ÑÐ¾ÐºÐµÐ½Ð° Ð´Ð¾ÑÑÑÐ¿Ð½Ð¾ ÑÐ¾Ð»ÑÐºÐ¾ Ð²Ð¾ Ð²ÑÐµÐ¼Ñ Ð¿Ð°ÑÐ·Ñ Ð°Ð´Ð¼Ð¸Ð½Ð¸ÑÑÑÐ°ÑÐ¾ÑÑ, Ð¿Ð¾ÑÐ»Ðµ Ð·Ð°Ð²ÐµÑÑÐµÐ½Ð¸Ñ Crowdsale ÑÑÐ½ÐºÑÐ¸Ñ ÑÑÐ°Ð½Ð¾Ð²Ð¸ÑÑÑ Ð½ÐµÐ´Ð¾ÑÑÑÐ¿Ð½Ð¾Ð¹
*/

contract Token is BurnableToken, MintableToken {
    string public name = "GBCoin";
    string public symbol = "GBCN";
    uint256 public decimals = 18;

    function Token() {
        MAX_SUPPLY = 40000000 * 1 ether;                                            // Maximum amount tokens
        mint(0xb942E28245d39ab4482e7C9972E07325B5653642, 20000000 * 1 ether);       
    }
}

contract Crowdsale is Pausable {
    using SafeMath for uint;

    Token public token;
    address public beneficiary = 0xb942E28245d39ab4482e7C9972E07325B5653642;        

    uint public collectedWei;
    uint public tokensSold;

    uint public tokensForSale = 20000000 * 1 ether;                                 // Amount tokens for sale
    uint public priceTokenWei = 1 ether / 25;                                       // 1 Eth (~875$) / 25 = ~35$

    bool public crowdsaleFinished = false;

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Withdraw();

    function Crowdsale() {
        token = new Token();
    }

    function() payable {
        purchase();
    }

    function setTokenPrice(uint _value) onlyOwner whenPaused {
        require(!crowdsaleFinished);
        priceTokenWei = 1 ether / _value;
    }
    
    function purchase() whenNotPaused payable {
        require(!crowdsaleFinished);
        require(tokensSold < tokensForSale);
        require(msg.value >= 0.01 ether && msg.value <= 10000 * 1 ether);

        uint sum = msg.value;
        uint amount = sum.div(priceTokenWei).mul(1 ether);
        uint retSum = 0;
        
        if(tokensSold.add(amount) > tokensForSale) {
            uint retAmount = tokensSold.add(amount).sub(tokensForSale);
            retSum = retAmount.mul(priceTokenWei).div(1 ether);

            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }

        tokensSold = tokensSold.add(amount);
        collectedWei = collectedWei.add(sum);

        beneficiary.transfer(sum);
        token.mint(msg.sender, amount);

        if(retSum > 0) {
            msg.sender.transfer(retSum);
        }

        NewContribution(msg.sender, amount, sum);
    }

    function withdraw() onlyOwner {
        require(!crowdsaleFinished);
        
        if(tokensForSale.sub(tokensSold) > 0) {
            token.mint(beneficiary, tokensForSale.sub(tokensSold));
        }

        token.finishMinting();
        token.transferOwnership(beneficiary);

        crowdsaleFinished = true;

        Withdraw();
    }

    function balanceOf(address _owner) constant returns(uint256 balance) {
        return token.balanceOf(_owner);
    }
}