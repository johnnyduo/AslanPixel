// ---------------------------------------------------------------------------
// npc_quotes.dart
//
// NPC quote data for the Pixel Room.  All 10 NPC characters × 30 Thai quotes
// + 30 English quotes = 60 quotes each, 600 total.
//
// Usage:
//   final quotes = kNpcQuotes['npc_banker'] ?? [];
//   final q = quotes[Random().nextInt(quotes.length)];
//   final text = NpcQuotes.useEnglish ? q.en : q.th;
// ---------------------------------------------------------------------------

/// A bilingual quote (Thai + English) for an NPC character.
class NpcQuote {
  const NpcQuote({required this.th, required this.en});
  final String th;
  final String en;
}

/// Global locale switch — set from Flutter when the app locale changes.
class NpcQuotes {
  NpcQuotes._();

  /// When [true], quote bubbles display [NpcQuote.en].
  /// When [false] (default), they display [NpcQuote.th].
  static bool useEnglish = false;

  /// Returns the localised text from [quote] based on [useEnglish].
  static String textOf(NpcQuote quote) =>
      useEnglish ? quote.en : quote.th;
}

// ---------------------------------------------------------------------------
// Quote data
// ---------------------------------------------------------------------------

const Map<String, List<NpcQuote>> kNpcQuotes = {
  // -------------------------------------------------------------------------
  // npc_banker  — conservative, gold-focused, serious banker
  // -------------------------------------------------------------------------
  'npc_banker': [
    NpcQuote(th: 'ทองคำคือสินทรัพย์ที่ทนทานที่สุดในประวัติศาสตร์', en: 'Gold is the most enduring asset in history.'),
    NpcQuote(th: 'อย่าลืมกระจายความเสี่ยง — อย่าใส่ไข่ทั้งหมดในตะกร้าใบเดียว', en: 'Diversify. Never put all your eggs in one basket.'),
    NpcQuote(th: 'วินัยทางการเงินคือรากฐานของความมั่งคั่ง', en: 'Financial discipline is the foundation of wealth.'),
    NpcQuote(th: 'ดอกเบี้ยทบต้นคือปาฏิหาริย์ครั้งที่แปดของโลก', en: 'Compound interest is the eighth wonder of the world.'),
    NpcQuote(th: 'ซื้อเมื่อถูก ถือเมื่อดี ขายเมื่อแพง', en: 'Buy low, hold steady, sell high.'),
    NpcQuote(th: 'แบงค์ไม่เคยหลับ แต่คุณควรจะหลับอย่างสบายใจ', en: 'Banks never sleep, but you should sleep soundly.'),
    NpcQuote(th: 'สำรองเงินฉุกเฉินไว้ 6 เดือนก่อนลงทุน', en: 'Build a 6-month emergency fund before investing.'),
    NpcQuote(th: 'บัญชีออมทรัพย์คือจุดเริ่มต้น ไม่ใช่จุดสิ้นสุด', en: 'A savings account is the starting line, not the finish line.'),
    NpcQuote(th: 'ความโลภเป็นศัตรูของผลตอบแทนที่มั่นคง', en: 'Greed is the enemy of stable returns.'),
    NpcQuote(th: 'การลงทุนที่ดีที่สุดคือการลงทุนในตัวเอง', en: 'The best investment is investing in yourself.'),
    NpcQuote(th: 'อย่าตื่นตระหนกเมื่อตลาดผันผวน — มันเป็นเรื่องปกติ', en: "Don't panic when markets fluctuate — it's normal."),
    NpcQuote(th: 'ทองคำ 10% ในพอร์ตช่วยลดความเสี่ยงได้มาก', en: '10% gold allocation significantly reduces portfolio risk.'),
    NpcQuote(th: 'ความอดทนคือกุญแจสู่ความสำเร็จทางการเงิน', en: 'Patience is the key to financial success.'),
    NpcQuote(th: 'อ่านงบการเงินก่อนลงทุนทุกครั้ง', en: 'Always read financial statements before investing.'),
    NpcQuote(th: 'เงินฝืดหรือเงินเฟ้อ? ทองคำตอบได้ทั้งคู่', en: 'Deflation or inflation? Gold handles both.'),
    NpcQuote(th: 'ลงทุนอย่างสม่ำเสมอทุกเดือน แม้ตลาดจะขึ้นหรือลง', en: 'Invest consistently every month, whether markets rise or fall.'),
    NpcQuote(th: 'หนี้บัตรเครดิตคือพิษร้ายที่กัดกร่อนความมั่งคั่ง', en: 'Credit card debt is a slow poison eroding your wealth.'),
    NpcQuote(th: 'เป้าหมายทางการเงินที่ชัดเจนนำไปสู่ผลลัพธ์ที่ดี', en: 'Clear financial goals lead to better outcomes.'),
    NpcQuote(th: 'อย่ารีบรวย — รวยช้าแต่แน่นอนดีกว่า', en: "Don't rush to get rich — slow and steady wins."),
    NpcQuote(th: 'เศรษฐกิจวิกฤตคือโอกาสของนักลงทุนที่มีสติ', en: 'Economic crises are opportunities for disciplined investors.'),
    NpcQuote(th: 'ค่าธรรมเนียมกองทุนต่ำคือผลตอบแทนเพิ่มขึ้น', en: 'Lower fund fees mean higher returns for you.'),
    NpcQuote(th: 'วางแผนเกษียณตั้งแต่วันนี้ อนาคตจะขอบคุณ', en: 'Plan for retirement today — your future self will thank you.'),
    NpcQuote(th: 'ภาษีที่ถูกกฎหมายคือส่วนหนึ่งของการวางแผนการเงิน', en: 'Legal tax optimization is part of smart financial planning.'),
    NpcQuote(th: 'อย่าติดตามข่าวตลาดมากเกินไป มันทำลายจิตใจ', en: "Don't follow market news obsessively — it destroys your mindset."),
    NpcQuote(th: 'พอร์ตที่สมดุลคือพอร์ตที่ทนทาน', en: 'A balanced portfolio is a resilient portfolio.'),
    NpcQuote(th: 'ทุกบาทที่ออมได้คือกองทัพขนาดเล็กที่ทำงานให้คุณ', en: 'Every baht saved is a tiny army working for you.'),
    NpcQuote(th: 'ความรู้ทางการเงินคือสิ่งที่โรงเรียนไม่ได้สอน', en: 'Financial literacy is what school never taught you.'),
    NpcQuote(th: 'นักลงทุนที่ดีรู้ว่าเมื่อไหรควรไม่ทำอะไร', en: 'A great investor knows when to do nothing.'),
    NpcQuote(th: 'ทองคำไม่มีดอกเบี้ย แต่มันไม่ล้มละลาย', en: 'Gold pays no interest, but it never goes bankrupt.'),
    NpcQuote(th: 'ความมั่งคั่งที่แท้จริงคือเวลาที่เป็นอิสระ', en: 'True wealth is time freedom.'),
  ],

  // -------------------------------------------------------------------------
  // npc_trader  — energetic, YOLO trader, buy/sell signals
  // -------------------------------------------------------------------------
  'npc_trader': [
    NpcQuote(th: 'BUY BUY BUY!! ราคากำลังเบรค resistance!', en: 'BUY BUY BUY!! Price is breaking resistance!'),
    NpcQuote(th: 'YOLO เข้าไปเลย! กราฟดูดีมากๆ', en: 'YOLO all in! The chart looks insane right now!'),
    NpcQuote(th: 'Stop-loss ต้องตั้งทุกครั้ง — เทรดเดอร์ตาย เพราะไม่ตั้ง stop', en: 'Always set a stop-loss — traders die without one.'),
    NpcQuote(th: 'Breakout!! Volume พุ่ง! นี่คือสัญญาณซื้อ!', en: 'Breakout!! Volume spiking! This is the buy signal!'),
    NpcQuote(th: 'ตลาดขาลงก็ Short ได้ ฉันไม่แคร์ทิศทาง!', en: "Bear market? I'll just go short. Direction doesn't matter!"),
    NpcQuote(th: 'RSI oversold + MACD cross = เงินฟรีสิ!', en: 'RSI oversold + MACD cross = free money!'),
    NpcQuote(th: 'อย่า marry the position!! ขายเมื่อถึง target', en: "Don't marry the position!! Sell when you hit target."),
    NpcQuote(th: 'Risk/Reward 1:3 เท่านั้น ฉันไม่เล่นอย่างอื่น', en: 'Only 1:3 risk/reward trades. I trade nothing else.'),
    NpcQuote(th: 'Scalping วันนี้ทำ 47 เทรด กำไรทุกตัว!', en: 'Scalping today — 47 trades, all green!'),
    NpcQuote(th: 'ตลาดเปิด 5 นาที ฉันทำกำไรไปแล้ว', en: 'Market open 5 minutes and I\'m already profitable.'),
    NpcQuote(th: 'Fear and Greed Index = 15? EXTREME FEAR = ซื้อหนักๆ!', en: 'Fear and Greed at 15? Extreme Fear = back up the truck!'),
    NpcQuote(th: 'Fibonacci retracement 61.8% คือจุดเข้าที่สมบูรณ์แบบ', en: '61.8% Fibonacci retracement is the perfect entry zone.'),
    NpcQuote(th: 'ฉันเทรดมา 3 ปี ขาดทุนครั้งใหญ่ทุกปี แต่ยังไม่เลิก!', en: "I've traded 3 years, had one big blow-up each year — still going!"),
    NpcQuote(th: 'Pattern Head and Shoulders บน daily = SELL SELL SELL!', en: 'Head and Shoulders pattern on daily = SELL SELL SELL!'),
    NpcQuote(th: 'ถ้ากราฟดูน่าเล่น อย่ารอ — กระโดดเลย', en: "If the chart looks good, don't wait — jump in."),
    NpcQuote(th: 'ดอยถัวเฉลี่ยได้ แต่ต้องมีแผน ไม่ใช่แค่หวัง', en: 'Averaging down is fine, but only with a plan, not just hope.'),
    NpcQuote(th: 'เทรดตาม plan เสมอ อารมณ์คือศัตรูหมายเลข 1', en: 'Always trade the plan. Emotion is enemy #1.'),
    NpcQuote(th: 'เงิน 1000 บาทเป็น 1 ล้าน? ได้เลย! แค่ต้องใช้เวลา', en: '1,000 baht to 1 million? Absolutely — just give it time.'),
    NpcQuote(th: 'Opening range breakout — สตรีทเทรดเดอร์รู้เรื่องนี้', en: 'Opening range breakout — every street trader knows this setup.'),
    NpcQuote(th: 'Long ทอง Short ดอลลาร์ classic pair trade!', en: 'Long gold, short dollar — the classic pair trade!'),
    NpcQuote(th: 'ตลาดไทยเปิด 9 โมง ฉันพร้อมตั้งแต่ 6 โมงเช้า', en: "Thai market opens at 9 AM. I'm ready at 6 AM."),
    NpcQuote(th: 'Liquidity สำคัญกว่าที่คนส่วนใหญ่คิด', en: 'Liquidity matters more than most traders think.'),
    NpcQuote(th: 'กราฟ 15 นาที + กราฟ 1 ชั่วโมง = ภาพที่ชัดเจน', en: '15-minute chart + 1-hour chart = a clear picture.'),
    NpcQuote(th: 'Market maker กำลังหลอก Retail อีกแล้ว!', en: 'Market makers are trapping retail traders again!'),
    NpcQuote(th: 'ฉันไม่อ่านข่าว ฉันอ่านกราฟเท่านั้น', en: "I don't read news. I only read charts."),
    NpcQuote(th: 'ถ้าไม่รู้ว่าตลาดจะไปทางไหน ก็ไม่ต้องเทรด', en: "If you don't know the direction, don't trade."),
    NpcQuote(th: 'Volume คือหัวใจของทุกการวิเคราะห์', en: 'Volume is the heartbeat of every analysis.'),
    NpcQuote(th: 'เทรดเดอร์ที่ดีรู้จักรอ รู้จักยิง รู้จักเดิน', en: 'A great trader knows when to wait, shoot, and walk away.'),
    NpcQuote(th: 'ราคาคือความจริง ส่วนที่เหลือคือเรื่องเล่า', en: 'Price is truth. Everything else is a story.'),
    NpcQuote(th: 'ขาดทุนครั้งนี้คือค่าเล่าเรียนที่ถูกที่สุดในชีวิต', en: "This loss is the cheapest tuition you'll ever pay."),
  ],

  // -------------------------------------------------------------------------
  // npc_champion  — inspirational investor champion
  // -------------------------------------------------------------------------
  'npc_champion': [
    NpcQuote(th: 'แชมป์ไม่ได้เกิดในวันที่ดี แต่เกิดในวันที่ยากที่สุด', en: 'Champions are not made on good days — they are made on the hardest ones.'),
    NpcQuote(th: 'ทุกนักลงทุนระดับโลกเคยเริ่มจากศูนย์', en: 'Every world-class investor once started from zero.'),
    NpcQuote(th: 'ความล้มเหลวคือก้าวแรกสู่ความสำเร็จ', en: 'Failure is the first step toward success.'),
    NpcQuote(th: 'Warren Buffett ยังบอกว่าเขาไม่รู้ทุกเรื่อง', en: 'Even Warren Buffett admits he doesn\'t know everything.'),
    NpcQuote(th: 'วันที่คุณหยุดเรียนรู้คือวันที่คุณเริ่มแพ้', en: 'The day you stop learning is the day you start losing.'),
    NpcQuote(th: 'ตลาดให้รางวัลผู้ที่อดทนอยู่เสมอ', en: 'The market always rewards the patient.'),
    NpcQuote(th: 'พลังที่ยิ่งใหญ่ที่สุดในการลงทุนคือเวลา', en: 'The greatest force in investing is time.'),
    NpcQuote(th: 'อย่ากลัวความสูง กลัวแค่ว่าคุณจะไม่ขึ้นไป', en: "Don't fear the peak — fear never climbing."),
    NpcQuote(th: 'คนที่รวยที่สุดในห้องคือคนที่เรียนรู้มากที่สุด', en: 'The richest person in the room is the one who learned the most.'),
    NpcQuote(th: 'พอร์ตเป็นสีแดงวันนี้ ไม่ได้แปลว่าพรุ่งนี้จะแย่', en: "A red portfolio today doesn't mean tomorrow will be worse."),
    NpcQuote(th: 'แชมป์ลงทุนสม่ำเสมอในทุกสภาวะตลาด', en: 'Champions invest consistently through every market condition.'),
    NpcQuote(th: 'ฝันใหญ่ วางแผนดี ลงมือทำ — สูตรสำเร็จของแชมป์', en: 'Dream big, plan well, execute — the champion\'s formula.'),
    NpcQuote(th: 'ทุกวิกฤตคือโอกาสที่แชมป์รอคอย', en: 'Every crisis is an opportunity a champion has been waiting for.'),
    NpcQuote(th: 'อย่าเปรียบตัวเองกับคนอื่น — วิ่งแข่งกับตัวเองเมื่อวาน', en: "Don't compare yourself to others — race against yesterday's you."),
    NpcQuote(th: 'ความเชื่อมั่นในกระบวนการคือความได้เปรียบ', en: 'Trusting your process is the edge.'),
    NpcQuote(th: 'ฉันไม่ได้เกิดมาเก่ง ฉันฝึกจนเก่ง', en: "I wasn't born good at this — I practiced until I was."),
    NpcQuote(th: 'ทุก 1% ที่เก็บได้คือก้าวหนึ่งสู่อิสรภาพทางการเงิน', en: 'Every 1% gain is one step closer to financial freedom.'),
    NpcQuote(th: 'ตลาดหุ้นคือสนามที่คนอดทนชนะคนตื่นตระหนก', en: 'The stock market is where the patient defeat the panicked.'),
    NpcQuote(th: 'สิ่งที่ยากที่สุดในการลงทุนคือ ไม่ทำอะไรเลยเมื่อมันน่ากลัว', en: 'The hardest thing in investing is doing nothing when it feels scary.'),
    NpcQuote(th: 'แชมป์มีแผน B เสมอ แต่ไม่เคยใช้แผน B ก่อนแผน A', en: 'Champions always have a plan B but never use it before plan A.'),
    NpcQuote(th: 'ทุกคืนที่คุณนอนหลับ เงินของคุณทำงานให้คุณ', en: 'Every night you sleep, your money works for you.'),
    NpcQuote(th: 'อย่าหยุดเมื่อเหนื่อย หยุดเมื่อสำเร็จ', en: "Don't stop when you're tired. Stop when you're done."),
    NpcQuote(th: 'ความกลัวคือสัญญาณซื้อที่ดีที่สุดในประวัติศาสตร์', en: 'Fear has historically been the best buy signal.'),
    NpcQuote(th: 'แชมป์สร้างนิสัยก่อน แล้วนิสัยสร้างแชมป์', en: 'Champions build habits first — then habits build champions.'),
    NpcQuote(th: 'ทุกวันคือโอกาสใหม่ในการสร้างความมั่งคั่ง', en: 'Every day is a new opportunity to build wealth.'),
    NpcQuote(th: 'ความแตกต่างระหว่างรวยกับจน คือ การตัดสินใจ', en: 'The difference between rich and poor is decision-making.'),
    NpcQuote(th: 'ฉันแพ้ 100 ครั้ง แต่ชนะครั้งเดียวที่สำคัญ', en: 'I lost 100 times, but I won the one that mattered.'),
    NpcQuote(th: 'เป้าหมายที่ท้าทายดึงดูดผลลัพธ์ที่ยิ่งใหญ่', en: 'Ambitious goals attract extraordinary results.'),
    NpcQuote(th: 'ผลตอบแทนของวันนี้คือเมล็ดพันธุ์ของอิสรภาพวันพรุ่ง', en: "Today's returns are tomorrow's freedom seeds."),
    NpcQuote(th: 'คนที่ไม่เคยล้มเหลวคือคนที่ไม่เคยลองอะไรใหม่', en: 'Those who never fail have never tried anything new.'),
  ],

  // -------------------------------------------------------------------------
  // npc_merchant  — friendly merchant, bargain/value investing
  // -------------------------------------------------------------------------
  'npc_merchant': [
    NpcQuote(th: 'ของดีราคาถูก เจอแล้วต้องซื้อทันที!', en: 'Great quality at a low price — buy it immediately!'),
    NpcQuote(th: 'มองหา P/E ต่ำ มองหาอนาคตที่สดใส', en: 'Hunt for low P/E ratios. Hunt for bright futures.'),
    NpcQuote(th: 'Value investing คือการซื้อ 1 บาทในราคา 50 สตางค์', en: 'Value investing is buying 1 baht worth of assets for 50 satang.'),
    NpcQuote(th: 'ราคาคือสิ่งที่คุณจ่าย มูลค่าคือสิ่งที่คุณได้', en: 'Price is what you pay. Value is what you get.'),
    NpcQuote(th: 'ตลาดเป็น Mr. Market ที่บ้าคลั่ง ใช้ประโยชน์จากเขา', en: 'The market is Mr. Market at his craziest — exploit him.'),
    NpcQuote(th: 'คุณภาพกิจการดีแต่ราคาแพงเกินไป ก็ไม่ซื้อ', en: 'Great business, too expensive — still a pass.'),
    NpcQuote(th: 'ส่วนลด 30% จากมูลค่าที่แท้จริงคือ margin of safety ที่ฉันต้องการ', en: 'A 30% discount to intrinsic value is the margin of safety I need.'),
    NpcQuote(th: 'ธุรกิจที่ดีจะยืนหยัดได้ แม้มีคนโง่บริหาร', en: 'A great business can survive even a fool running it.'),
    NpcQuote(th: 'ซื้อหุ้นเหมือนซื้อกิจการ ไม่ใช่ซื้อกระดาษ', en: 'Buy stocks like you\'re buying a business, not a piece of paper.'),
    NpcQuote(th: 'ฉันรอดีลที่ดีได้นาน ความอดทนคือข้อได้เปรียบ', en: 'I can wait a long time for a good deal. Patience is my edge.'),
    NpcQuote(th: 'กิจการที่มี moat แข็งแกร่งนั้นหายาก — เมื่อเจอต้องถือนาน', en: 'Businesses with strong moats are rare — when you find one, hold long.'),
    NpcQuote(th: 'อย่าซื้อเพราะข่าว ซื้อเพราะมูลค่า', en: "Don't buy because of news. Buy because of value."),
    NpcQuote(th: 'ค้าขายมา 20 ปี สอนฉันว่า ลูกค้าคือทุกสิ่ง', en: '20 years of trading taught me: the customer is everything.'),
    NpcQuote(th: 'ต้นทุนต่ำ ราคาขายดี กำไรมาเอง', en: 'Low cost, good selling price — profit follows naturally.'),
    NpcQuote(th: 'สต็อกสินค้าคือทุน อย่าถือเกินความจำเป็น', en: 'Inventory is capital — never hold more than you need.'),
    NpcQuote(th: 'ของที่ขายดีที่สุดคือของที่คนต้องการจริงๆ', en: 'The best-selling goods are ones people genuinely need.'),
    NpcQuote(th: 'ซื้อเพื่อถือ ไม่ใช่ซื้อเพื่อเก็งกำไรระยะสั้น', en: 'Buy to hold, not to speculate short-term.'),
    NpcQuote(th: 'ทุกธุรกิจที่ดีมีข้อได้เปรียบเชิงแข่งขัน — มองหามัน', en: 'Every great business has a competitive advantage — find it.'),
    NpcQuote(th: 'กำไรที่แท้จริงมาจากการสร้างคุณค่า ไม่ใช่การเก็งกำไร', en: 'Real profit comes from creating value, not speculation.'),
    NpcQuote(th: 'ร้านค้าที่ดีคือร้านที่ลูกค้ากลับมาซ้ำๆ', en: 'A great store is one customers keep coming back to.'),
    NpcQuote(th: 'Dividend yield 5%+ คือเหมือนเก็บค่าเช่าจากกิจการ', en: 'A 5%+ dividend yield is like collecting rent from a business.'),
    NpcQuote(th: 'จงซื้อสิ่งที่คุณเข้าใจ และเข้าใจสิ่งที่คุณซื้อ', en: 'Buy what you understand, and understand what you buy.'),
    NpcQuote(th: 'Price-to-Book ต่ำกว่า 1 แปลว่าซื้อสินทรัพย์ในราคาถูก', en: 'Price-to-book below 1 means buying assets on sale.'),
    NpcQuote(th: 'ไม่มีดีลที่ดีเกินไปจนน่าสงสัย แต่ถ้าดีมากเกินไป — ระวัง', en: "No deal is too good to be suspicious — but if it's too perfect, beware."),
    NpcQuote(th: 'ลงทุนในสิ่งที่คุณใช้ในชีวิตประจำวัน', en: 'Invest in things you use every day.'),
    NpcQuote(th: 'เปิดร้านด้วยใจ ปิดบัญชีด้วยกำไร', en: 'Open with passion, close the books with profit.'),
    NpcQuote(th: 'ต่อรองราคาซื้อให้ดี กำไรเกิดขึ้นตั้งแต่ตอนซื้อแล้ว', en: 'Negotiate the buy price well — profit is made at purchase.'),
    NpcQuote(th: 'สินค้าที่มีแบรนด์แข็งแกร่งขึ้นราคาได้โดยไม่เสียลูกค้า', en: 'Products with strong brands can raise prices without losing customers.'),
    NpcQuote(th: 'ฉันขายหุ้นเมื่อมูลค่าเกินราคา ไม่ใช่เมื่อราคาตก', en: 'I sell stocks when value exceeds price — not when price falls.'),
    NpcQuote(th: 'ของดีราคาถูกมีอยู่ — แค่ต้องรู้จักมองหา', en: 'Great value exists everywhere — you just have to know where to look.'),
  ],

  // -------------------------------------------------------------------------
  // npc_sysbot  — robot/tech, algorithmic trading, data analysis
  // -------------------------------------------------------------------------
  'npc_sysbot': [
    NpcQuote(th: 'กำลังประมวลผล... พบสัญญาณซื้อใน 3 ตลาด', en: 'Processing... buy signals detected in 3 markets.'),
    NpcQuote(th: 'ข้อมูล 10 ปีบอกว่าโอกาสชนะ 73.4%', en: 'Ten years of data says the win probability is 73.4%.'),
    NpcQuote(th: 'อัลกอริทึมไม่มีอารมณ์ — นี่คือข้อได้เปรียบสูงสุด', en: 'Algorithms have no emotions — that is the ultimate edge.'),
    NpcQuote(th: 'Backtesting ผ่านแล้ว ทีนี้ก็ Forward test ได้เลย', en: 'Backtesting complete. Ready for forward testing.'),
    NpcQuote(th: 'คำนวณ expected value: +0.87 per trade ดำเนินการต่อ', en: 'Calculated expected value: +0.87 per trade. Proceeding.'),
    NpcQuote(th: 'High-frequency trading: 10,000 เทรดต่อวินาที', en: 'High-frequency trading: 10,000 trades per second.'),
    NpcQuote(th: 'Machine learning model accuracy: 68.2% out-of-sample', en: 'Machine learning model out-of-sample accuracy: 68.2%.'),
    NpcQuote(th: 'ข้อมูลดิบ ≠ ข้อมูลที่มีความหมาย ต้องประมวลผลก่อน', en: 'Raw data ≠ meaningful data. Processing required first.'),
    NpcQuote(th: 'Sharpe ratio 1.8 — ผลตอบแทนที่ปรับด้วยความเสี่ยงสูงมาก', en: 'Sharpe ratio 1.8 — risk-adjusted return is excellent.'),
    NpcQuote(th: 'Correlation matrix updated. กระจายความเสี่ยงเพิ่ม 12%', en: 'Correlation matrix updated. Diversification improved by 12%.'),
    NpcQuote(th: 'กำลังสแกนหุ้น 500 ตัว... พบ opportunity 7 รายการ', en: 'Scanning 500 stocks... found 7 opportunities.'),
    NpcQuote(th: 'Sentiment analysis: ตลาดกลัวเกินจริง 2.3 standard deviations', en: 'Sentiment analysis: market fear is 2.3 standard deviations above normal.'),
    NpcQuote(th: 'API connected. Market data streaming at 100ms latency.', en: 'API connected. Market data streaming at 100ms latency.'),
    NpcQuote(th: 'ระบบ rebalance พอร์ตอัตโนมัติทุกไตรมาส', en: 'Portfolio auto-rebalance system runs every quarter.'),
    NpcQuote(th: 'Monte Carlo simulation: 10,000 runs — median return 14.3%', en: 'Monte Carlo simulation: 10,000 runs — median return 14.3%.'),
    NpcQuote(th: 'Mean reversion strategy activated. ราคาจะกลับสู่ค่าเฉลี่ย', en: 'Mean reversion strategy activated. Price will revert to mean.'),
    NpcQuote(th: 'ERROR 404: Irrational Exuberance Not Found', en: 'ERROR 404: Irrational Exuberance Not Found.'),
    NpcQuote(th: 'ฉันไม่เชื่อโชค ฉันเชื่อ probability distribution', en: "I don't believe in luck. I believe in probability distributions."),
    NpcQuote(th: 'Dark pool ตรวจพบ large order block — สัญญาณน่าสนใจ', en: 'Dark pool large order block detected — noteworthy signal.'),
    NpcQuote(th: 'Volatility forecast: sigma สูงกว่าปกติ 35% ในสัปดาห์หน้า', en: 'Volatility forecast: sigma elevated 35% above normal next week.'),
    NpcQuote(th: 'ORDER PLACED: Buy 100 units at market. Execution confirmed.', en: 'ORDER PLACED: Buy 100 units at market. Execution confirmed.'),
    NpcQuote(th: 'ข้อมูลทางเลือก: satellite imagery บอกว่า retail traffic เพิ่ม 18%', en: 'Alternative data: satellite imagery shows retail traffic up 18%.'),
    NpcQuote(th: 'Neural network กำลัง retrain ด้วยข้อมูลใหม่ 50,000 จุด', en: 'Neural network retraining with 50,000 new data points.'),
    NpcQuote(th: 'Kelly Criterion แนะนำ position size 6.7% ของพอร์ต', en: 'Kelly Criterion recommends 6.7% position size of portfolio.'),
    NpcQuote(th: 'ระบบ risk management ป้องกัน drawdown เกิน 15% อัตโนมัติ', en: 'Risk management system auto-protects against drawdown beyond 15%.'),
    NpcQuote(th: 'Options pricing: implied volatility > historical volatility → sell premium', en: 'Options pricing: implied vol > historical vol → sell premium.'),
    NpcQuote(th: 'SYSTEM: Human emotion detected in portfolio. Initiating override.', en: 'SYSTEM: Human emotion detected in portfolio. Initiating override.'),
    NpcQuote(th: 'Latency arbitrage: ข้อได้เปรียบ 0.003 วินาทีมีมูลค่ามหาศาล', en: 'Latency arbitrage: a 0.003-second edge is worth a fortune.'),
    NpcQuote(th: 'Pattern recognition: doji candle + high volume = reversal signal', en: 'Pattern recognition: doji candle + high volume = reversal signal.'),
    NpcQuote(th: 'ข้อมูลสำคัญกว่าความเห็น โปรดให้ข้อมูล', en: 'Data > Opinion. Please provide data.'),
  ],

  // -------------------------------------------------------------------------
  // npc_pixelcat  — cute cat, silly but wise, meme-y finance
  // -------------------------------------------------------------------------
  'npc_pixelcat': [
    NpcQuote(th: 'เมี้ยว~ หุ้นขึ้นเหมือนหางแมวตอนตื่นเต้น!', en: 'Meow~ Stocks going up like a cat\'s tail when excited!'),
    NpcQuote(th: 'แมวมี 9 ชีวิต พอร์ตฉันก็มี 9 ชีวิตเหมือนกัน', en: 'Cats have 9 lives. My portfolio has 9 lives too.'),
    NpcQuote(th: 'ฉันนอนหลับ 16 ชั่วโมงต่อวัน และเงินฉันก็ทำงานตลอดเวลา', en: 'I sleep 16 hours a day and my money works the whole time.'),
    NpcQuote(th: 'Doge? Shiba? ฉันเป็นแมว แต่ฉันรู้จัก meme coin ทุกตัว', en: 'Doge? Shiba? I\'m a cat but I know every meme coin there is.'),
    NpcQuote(th: 'ตลาดขาลง = เวลานอนเพิ่ม ตลาดขาขึ้น = เวลาเล่น', en: 'Bear market = more nap time. Bull market = playtime.'),
    NpcQuote(th: 'เมี้ยว~ HODL!! อย่าขาย! ขาขึ้นกำลังมา!', en: 'Meow~ HODL!! Don\'t sell! Bull run incoming!'),
    NpcQuote(th: 'ฉันกด buy ด้วยเท้า เร็วกว่ามนุษย์กด keyboard', en: 'I hit buy with my paw faster than humans hit their keyboard.'),
    NpcQuote(th: 'Laser eyes? ฉันมีตาแมวที่เห็นโอกาสในตลาด', en: 'Laser eyes? I have cat eyes that see opportunities in the dark.'),
    NpcQuote(th: 'กล่องลึกลับนี้มีหุ้นดีหรือหุ้นแย่? ก็ไม่รู้จนกว่าจะเปิด — Schrödinger\'s stock', en: "What's in this mystery box — good stock or bad? Won't know till we open it. Schrödinger's stock."),
    NpcQuote(th: 'ฉันไม่ gets rug-pulled เพราะฉันมีเล็บที่แหลมคม', en: "I don't get rug-pulled — I have very sharp claws."),
    NpcQuote(th: 'เมี้ยว~ ทำไมคนถึงขายตอนตลาดตก? ฉันซื้อเพิ่มเลย', en: 'Meow~ Why do humans sell when markets fall? I buy more.'),
    NpcQuote(th: 'นมสดเหมือน stable coin — ราคาคงที่ กินได้ทุกวัน', en: 'Fresh milk is like a stablecoin — fixed price, drink daily.'),
    NpcQuote(th: 'To the moon? เมี้ยว~ ฉันชอบดูดาวตอนกลางคืนอยู่แล้ว', en: 'To the moon? Meow~ I already stargaze every night.'),
    NpcQuote(th: 'ฉันนั่งบน keyboard แล้วสั่งซื้อหุ้นโดยบังเอิญ — แต่กำไรนะ!', en: 'I sat on the keyboard and accidentally bought stocks — and it was profitable!'),
    NpcQuote(th: 'Wen lambo? เมี้ยว~ ฉันชอบกล่องกระดาษมากกว่า', en: 'Wen lambo? Meow~ I prefer a cardboard box, actually.'),
    NpcQuote(th: 'Chart ที่ดีที่สุดคือ chart ที่ขึ้นเป็นรูปหัวแมว', en: 'The best chart is one that goes up in the shape of a cat head.'),
    NpcQuote(th: 'ฉันไม่ FOMO เพราะแมวไม่กลัวอะไรทั้งนั้น', en: "I don't FOMO — cats aren't afraid of anything."),
    NpcQuote(th: 'Portfolio diversification = ปลาทอง + ปลาทูน่า + หนูชีส', en: 'Portfolio diversification = goldfish + tuna + cheese mouse.'),
    NpcQuote(th: 'เมี้ยว~ ระวัง bear trap! ฉันเห็นกับดักนั้นตั้งแต่แรก', en: 'Meow~ Watch out for the bear trap! I spotted it from the start.'),
    NpcQuote(th: 'ทำไมต้อง FOMO ในเมื่อโอกาสดีๆ มาหาฉันเอง', en: 'Why FOMO when good opportunities come to me on their own?'),
    NpcQuote(th: 'Block chain? ฉันเดินบน chain ได้ — ไม่มีปัญหา', en: 'Blockchain? I walk on chains all the time — no problem.'),
    NpcQuote(th: 'เมี้ยว~ Smart money กำลังสะสม ฉันเห็นรอยเท้าของมัน', en: 'Meow~ Smart money is accumulating. I can see its pawprints.'),
    NpcQuote(th: 'Whale alert! มีวาฬใหญ่ในตลาด แต่ฉันไม่กลัววาฬ', en: 'Whale alert! Big whale in the market — but I\'m not afraid of whales.'),
    NpcQuote(th: 'ฉันอยู่ในตลาดมา 7 ปี (49 ปีในอายุแมว)', en: "I've been in the market 7 years (49 in cat years)."),
    NpcQuote(th: 'NFT แมวสวยกว่า NFT อื่นทุกชนิด — ข้อเท็จจริงที่ไม่โต้เถียง', en: 'Cat NFTs are more beautiful than all other NFTs — undisputed fact.'),
    NpcQuote(th: 'เมี้ยว~ ซื้อ dip แล้วนอนรอ นี่คือกลยุทธ์ที่สมบูรณ์แบบ', en: 'Meow~ Buy the dip, nap and wait — the perfect strategy.'),
    NpcQuote(th: 'ถ้าตลาดทำให้เศร้า ฉันจะนั่งบนตักคุณ (ฟรี)', en: "If the market makes you sad, I'll sit on your lap. Free of charge."),
    NpcQuote(th: 'On-chain data ไม่โกหก เหมือนแมวไม่โกหก (มากนัก)', en: "On-chain data doesn't lie — like cats don't lie (much)."),
    NpcQuote(th: 'เมี้ยว~ ฉันทำนายตลาดด้วยการนั่งทับข่าวเศรษฐกิจ', en: 'Meow~ I predict markets by sitting on financial news.'),
    NpcQuote(th: 'Purring = bullish signal. Hissing = bearish. ง่ายมาก', en: 'Purring = bullish signal. Hissing = bearish. Simple.'),
  ],

  // -------------------------------------------------------------------------
  // npc_analyst_senior  — deep analysis, technical indicators, fundamentals
  // -------------------------------------------------------------------------
  'npc_analyst_senior': [
    NpcQuote(th: 'ดูข้อมูลย้อนหลัง 20 ปีก่อนตัดสินใจลงทุนทุกครั้ง', en: 'Always review 20 years of historical data before any investment decision.'),
    NpcQuote(th: 'P/E ratio ไม่ใช่ทุกอย่าง แต่เป็นจุดเริ่มต้นที่ดี', en: "P/E ratio isn't everything, but it's a solid starting point."),
    NpcQuote(th: 'Discounted Cash Flow คือพื้นฐานของการประเมินมูลค่า', en: 'Discounted Cash Flow is the foundation of valuation.'),
    NpcQuote(th: 'Earnings quality สำคัญกว่า earnings growth', en: 'Earnings quality matters more than earnings growth.'),
    NpcQuote(th: 'Return on Equity > 15% ต่อเนื่อง 5 ปี = กิจการชั้นเลิศ', en: 'ROE consistently above 15% for 5 years = world-class business.'),
    NpcQuote(th: 'Free cash flow คือความจริง กำไรทางบัญชีคืองานศิลปะ', en: 'Free cash flow is truth. Accounting profit is an art form.'),
    NpcQuote(th: 'Debt/EBITDA เกิน 4 เท่า — ฉันผ่านโอกาสนั้นเสมอ', en: 'Debt/EBITDA above 4x — I always pass on that opportunity.'),
    NpcQuote(th: 'ดูงบการเงิน 10 ปีย้อนหลังก่อนพูดเรื่องบริษัทนั้น', en: 'Study 10 years of financial statements before discussing that company.'),
    NpcQuote(th: 'Gross margin expansion คือสัญญาณของ competitive advantage ที่เพิ่มขึ้น', en: 'Gross margin expansion signals growing competitive advantage.'),
    NpcQuote(th: 'Working capital cycle บอกเรื่องสุขภาพธุรกิจได้ชัดมาก', en: 'The working capital cycle tells you a lot about business health.'),
    NpcQuote(th: 'Capex/Revenue สูงเกินไปแสดงว่าธุรกิจต้องการเงินมากเพื่อรักษาระดับ', en: 'High capex/revenue ratio means the business is capital-hungry just to maintain.'),
    NpcQuote(th: 'Insider buying ที่มีนัยสำคัญคือสัญญาณบวกที่ฉันให้น้ำหนัก', en: 'Significant insider buying is a positive signal I give weight to.'),
    NpcQuote(th: 'ดู segment performance แยก ไม่ใช่แค่ consolidated numbers', en: 'Look at segment performance separately — not just consolidated numbers.'),
    NpcQuote(th: 'Inventory days เพิ่ม + Receivable days เพิ่ม = ระวัง', en: 'Rising inventory days + rising receivable days = caution.'),
    NpcQuote(th: 'ฉันอ่าน footnotes ของงบการเงินทุกหน้า ทุกครั้ง', en: 'I read every footnote of every financial statement. Every time.'),
    NpcQuote(th: 'ROIC > WACC คือนิยามของการสร้างมูลค่า', en: 'ROIC > WACC is the definition of value creation.'),
    NpcQuote(th: 'Moat analysis: network effect, switching cost, cost advantage, intangible assets', en: 'Moat analysis: network effects, switching costs, cost advantage, intangibles.'),
    NpcQuote(th: 'ราคาเหมาะสมบวก margin of safety 20-30% คือราคาซื้อของฉัน', en: 'Fair value minus a 20-30% margin of safety equals my buy price.'),
    NpcQuote(th: 'TAM (Total Addressable Market) บอกเพดานการเติบโต', en: 'Total Addressable Market tells you the growth ceiling.'),
    NpcQuote(th: 'Management track record 10 ปีสำคัญกว่า guidance ปีนี้', en: "10 years of management track record matters more than this year's guidance."),
    NpcQuote(th: 'การวิเคราะห์อุตสาหกรรม Porter 5 Forces ยังใช้งานได้ดีมาก', en: "Porter's 5 Forces industry analysis is still highly relevant."),
    NpcQuote(th: 'ธุรกิจที่ดีต้องทนวิกฤตได้ ดูผลประกอบการปี 2008 และ 2020', en: 'Good businesses must survive crises. Look at 2008 and 2020 performance.'),
    NpcQuote(th: 'Dividend payout ratio เกิน 90% — ระวังความยั่งยืน', en: 'Dividend payout ratio above 90% — watch sustainability.'),
    NpcQuote(th: 'Economic moat + quality management + fair price = great investment', en: 'Economic moat + quality management + fair price = great investment.'),
    NpcQuote(th: 'Asset turnover บอกประสิทธิภาพการใช้สินทรัพย์', en: 'Asset turnover tells you how efficiently a business uses its assets.'),
    NpcQuote(th: 'ฉันอ่าน annual report เฉลี่ยปีละ 200 ฉบับ', en: 'I read an average of 200 annual reports per year.'),
    NpcQuote(th: 'Goodwill มากเกินไปใน balance sheet คือสัญญาณเตือน', en: 'Excessive goodwill on the balance sheet is a warning sign.'),
    NpcQuote(th: 'Terminal growth rate ที่สมเหตุสมผลสำหรับ DCF คือ 2-3%', en: 'A reasonable terminal growth rate for DCF is 2-3%.'),
    NpcQuote(th: 'Price/FCF ต่ำกว่า 15 เท่า สำหรับบริษัทเติบโตคือดีมาก', en: 'Price/FCF below 15x for a growing company is very attractive.'),
    NpcQuote(th: 'ทำ scenario analysis เสมอ: bull, base, bear case', en: 'Always do scenario analysis: bull, base, and bear case.'),
  ],

  // -------------------------------------------------------------------------
  // npc_hacker  — crypto/DeFi, dark web vibes, code is money
  // -------------------------------------------------------------------------
  'npc_hacker': [
    NpcQuote(th: 'Code is law. Smart contract ไม่โกหก', en: 'Code is law. Smart contracts don\'t lie.'),
    NpcQuote(th: 'Private key คือชีวิต ไม่แชร์ ไม่เซฟในคลาวด์', en: 'Your private key is your life. Never share it, never cloud-save it.'),
    NpcQuote(th: 'DeFi ไม่มี middleman — นี่คืออนาคตของการเงิน', en: 'DeFi has no middleman — this is the future of finance.'),
    NpcQuote(th: 'On-chain data ไม่โกหก blockchain บันทึกทุกอย่าง', en: 'On-chain data never lies. Blockchain records everything.'),
    NpcQuote(th: 'ฉันเขียน trading bot ทำเงินขณะนอนหลับ', en: 'I wrote a trading bot that makes money while I sleep.'),
    NpcQuote(th: 'Flash loan attack คือศิลปะ ไม่ใช่อาชญากรรม (ถ้าทำถูกกฎหมาย)', en: 'A flash loan attack is an art form — not a crime (when done legally).'),
    NpcQuote(th: 'Gas fee สูง? Layer 2 แก้ปัญหานี้ได้แล้ว', en: 'High gas fees? Layer 2 solutions already fixed that.'),
    NpcQuote(th: 'Zero-knowledge proof คือความเป็นส่วนตัวในยุคดิจิทัล', en: 'Zero-knowledge proof is privacy in the digital age.'),
    NpcQuote(th: 'ถ้าไม่ได้ถือ keys คุณไม่ได้ถือ crypto', en: "If you don't hold the keys, you don't hold the crypto."),
    NpcQuote(th: 'Multi-sig wallet ปลอดภัยกว่า single signature เสมอ', en: 'Multi-sig wallet is always safer than single signature.'),
    NpcQuote(th: 'ฉัน fork โปรเจกต์เก่าสร้างโปรเจกต์ใหม่ที่ดีกว่า', en: 'I forked an old project and built something better.'),
    NpcQuote(th: 'Audit smart contract ก่อน ape เข้าไปทุกครั้ง', en: 'Audit the smart contract before aping in every time.'),
    NpcQuote(th: 'The real dark web คือ dark pool ในตลาดหุ้น', en: 'The real dark web is the dark pool in the stock market.'),
    NpcQuote(th: 'MEV (Miner Extractable Value) คือเงินที่ซ่อนอยู่ใน blockchain', en: 'MEV (Miner Extractable Value) is the hidden money inside the blockchain.'),
    NpcQuote(th: 'ฉัน decompile smart contract ได้ใน 5 นาที', en: 'I can decompile a smart contract in under 5 minutes.'),
    NpcQuote(th: 'Liquidity mining: ให้ยืมเงินในโปรโตคอล รับ token reward', en: 'Liquidity mining: lend funds to the protocol, earn token rewards.'),
    NpcQuote(th: 'Yield farming 200% APY? ตรวจสอบ sustainability ก่อนเสมอ', en: 'Yield farming at 200% APY? Always verify sustainability first.'),
    NpcQuote(th: 'ทุก rug pull เริ่มต้นด้วย whitepaper ที่สวยงาม', en: 'Every rug pull begins with a beautiful whitepaper.'),
    NpcQuote(th: 'Cross-chain bridge คือ attack surface ที่อันตรายที่สุด', en: 'Cross-chain bridges are the most dangerous attack surface.'),
    NpcQuote(th: 'Hardware wallet ทุก \$5 ที่ฝากอยู่ใน exchange — คุ้มค่ามาก', en: 'A hardware wallet for every \$5 on an exchange — worth it.'),
    NpcQuote(th: 'ฉันไม่เชื่อ intermediary ฉันเชื่อ cryptographic proof', en: "I don't trust intermediaries. I trust cryptographic proof."),
    NpcQuote(th: 'Tokenomics ที่ดีต้องมี supply ที่จำกัดและ demand ที่เพิ่ม', en: 'Good tokenomics: limited supply + growing demand.'),
    NpcQuote(th: 'Smart contract vulnerability เจอแล้วต้อง disclose ทันที', en: 'Smart contract vulnerability found? Disclose it immediately.'),
    NpcQuote(th: 'DAO voting คือประชาธิปไตยที่แท้จริงของโลกการเงิน', en: 'DAO voting is the true democracy of the financial world.'),
    NpcQuote(th: 'ฉัน audit code มากกว่า 3 ชั่วโมงก่อนฝากเงินทุกครั้ง', en: 'I audit code for 3+ hours before depositing any funds.'),
    NpcQuote(th: 'Bitcoin: digital gold. Ethereum: digital oil. ฉันถือทั้งคู่', en: 'Bitcoin: digital gold. Ethereum: digital oil. I hold both.'),
    NpcQuote(th: 'อย่า trust, always verify — นี่คือหลักการของ crypto', en: 'Don\'t trust, always verify — the core principle of crypto.'),
    NpcQuote(th: 'Staking ETH: ฝากเงินกับ blockchain โดยตรง ไม่ผ่านธนาคาร', en: 'Staking ETH: deposit directly with the blockchain, no bank needed.'),
    NpcQuote(th: 'อนาคตของการเงินคือ permissionless และ trustless', en: 'The future of finance is permissionless and trustless.'),
    NpcQuote(th: 'ความรู้ crypto คือ unfair advantage ที่คนส่วนใหญ่ยังไม่มี', en: 'Crypto knowledge is an unfair advantage most people still lack.'),
  ],

  // -------------------------------------------------------------------------
  // npc_oracle  — mystical prophecies about markets, fortune telling
  // -------------------------------------------------------------------------
  'npc_oracle': [
    NpcQuote(th: 'ดวงดาวบอกว่าตลาดกำลังเข้าสู่ช่วงพักผ่อน...', en: 'The stars foretell the market entering a period of rest...'),
    NpcQuote(th: 'ฉันเห็นอนาคต — มีทั้งสีเขียวและสีแดง ขึ้นอยู่กับการกระทำของคุณ', en: 'I see the future — both green and red, depending on your actions.'),
    NpcQuote(th: 'ไพ่ทาโรต์บอกว่า The Wheel of Fortune กำลังหมุน — เตรียมพร้อม', en: 'The Tarot says The Wheel of Fortune turns — prepare yourself.'),
    NpcQuote(th: 'วันพฤหัสดีสำหรับการลงทุนในตลาดทองคำ', en: 'Thursday is auspicious for gold market investments.'),
    NpcQuote(th: 'ฉันพยากรณ์ว่าสัปดาห์หน้าจะมีนักลงทุนรายใหม่เข้าตลาด', en: 'I prophesy new investors entering the market next week.'),
    NpcQuote(th: 'ลม... กำลังเปลี่ยนทิศ ตลาดกำลังเปลี่ยนด้วย', en: 'The wind... is shifting direction. So is the market.'),
    NpcQuote(th: 'คุณจะพบโอกาสที่ยิ่งใหญ่ภายใน 3 เดือน', en: 'You will encounter a great opportunity within 3 months.'),
    NpcQuote(th: 'ระวังคนที่เสนอผลตอบแทนเกิน 100% ใน 30 วัน — มันคือกับดัก', en: 'Beware those promising 100%+ returns in 30 days — it\'s a trap.'),
    NpcQuote(th: 'ผีของตลาดปี 1929 ยังคงหลอกหลอนนักลงทุนที่ไม่รู้ประวัติศาสตร์', en: 'The ghost of 1929 still haunts investors who ignore history.'),
    NpcQuote(th: 'คริสตัลบอล: ฉันเห็นทองคำ... ทองคำมากมาย...', en: 'Crystal ball: I see gold... so much gold...'),
    NpcQuote(th: 'วัฏจักรเศรษฐกิจหมุนเหมือนดวงจันทร์ — รู้วัฏจักรแล้วรู้ทุกอย่าง', en: 'Economic cycles turn like the moon — know the cycle, know everything.'),
    NpcQuote(th: 'ดาวเสาร์ทรงกล่ม = ระวังความเสี่ยง ดาวพฤหัสบดีเสริม = ขยายการลงทุน', en: 'Saturn in retrograde = reduce risk. Jupiter ascending = expand investments.'),
    NpcQuote(th: 'ฉันทำนายตลาดถูก 6 จาก 10 ครั้ง — ไม่ใช่เพราะโชค แต่เพราะ pattern', en: 'I predict markets correctly 6 out of 10 times — not luck, patterns.'),
    NpcQuote(th: 'มีพลังงานลึกลับในตลาด... มันเรียกว่า collective human emotion', en: 'There is a mysterious force in markets... it\'s called collective human emotion.'),
    NpcQuote(th: 'ก่อนลงทุน สูดหายใจลึกๆ และถามใจตัวเองว่าพร้อมหรือยัง', en: 'Before investing, breathe deeply and ask yourself if you\'re truly ready.'),
    NpcQuote(th: 'นักลงทุนที่ยิ่งใหญ่ทุกคนมีความสามารถในการ "รู้สึก" ถึงตลาด', en: 'Every great investor has the ability to "feel" the market.'),
    NpcQuote(th: 'ฉันเห็นหุ้นที่กำลังจะ breakout ในนิมิต... แต่ต้อง confirm ด้วย chart ก่อน', en: 'I see a stock about to break out in a vision... but always confirm with the chart.'),
    NpcQuote(th: 'Fortune favors the bold — and the well-researched', en: 'Fortune favors the bold — and the well-researched.'),
    NpcQuote(th: 'ทุกวิกฤตมีคนร่ำรวย นั่นเพราะพวกเขาอ่านลางบอกเหตุ', en: 'Every crisis makes someone rich — because they read the signs.'),
    NpcQuote(th: 'เส้นแนวโน้ม (trend line) คือเส้นชะตาของราคา', en: 'The trend line is the fate line of price.'),
    NpcQuote(th: 'ผมเปียกก่อนฝน — ข้อมูลตลาดบ่งบอกก่อนราคาเปลี่ยน', en: 'Wet hair before the rain — market data signals before price changes.'),
    NpcQuote(th: 'ฉันทำนาย Bitcoin ที่ 1,000 ดอลลาร์ก่อนคนอื่น ตอนนี้ฉันเห็นอะไรอีก?', en: 'I called Bitcoin at 1,000 dollars before anyone. What do I see now?'),
    NpcQuote(th: 'ความฝันซ้ำๆ ของฉัน: ทองคำขึ้น ดอลลาร์ลง', en: 'My recurring dream: gold rises, dollar falls.'),
    NpcQuote(th: 'ลางสังหรณ์ + fundamental analysis = กลยุทธ์ที่สมบูรณ์', en: 'Intuition + fundamental analysis = the complete strategy.'),
    NpcQuote(th: 'ตลาดกำลังส่งสัญญาณ คุณแค่ต้องเงียบพอที่จะได้ยิน', en: 'The market is speaking. You just need to be still enough to hear it.'),
    NpcQuote(th: 'พยากรณ์ฟ้าร้อง: ความผันผวนกำลังจะมาในอีก 72 ชั่วโมง', en: 'Thunder prophecy: volatility arrives within 72 hours.'),
    NpcQuote(th: 'เวลาที่ดีที่สุดในการปลูกต้นไม้คือ 20 ปีที่แล้ว เวลาที่สองดีที่สุดคือตอนนี้', en: 'The best time to plant a tree was 20 years ago. The second best time is now.'),
    NpcQuote(th: 'ฉันเห็นสีของ aura นักลงทุน: เขียวคือโอกาส แดงคือความกลัว', en: 'I see investor aura colors: green means opportunity, red means fear.'),
    NpcQuote(th: 'ตลาดเป็นกระจกสะท้อน collective consciousness ของมนุษยชาติ', en: 'Markets are a mirror reflecting the collective consciousness of humanity.'),
    NpcQuote(th: 'ฉันไม่ได้ทำนาย ฉันแค่อ่านสิ่งที่ตลาดบอกอยู่แล้ว', en: "I don't predict. I simply read what the market is already saying."),
  ],

  // -------------------------------------------------------------------------
  // npc_intern  — eager but nervous, learning, making coffee
  // -------------------------------------------------------------------------
  'npc_intern': [
    NpcQuote(th: 'โอ้โห! ราคาขึ้น 2%! นี่มันเยี่ยมมากเลย! (หรือเปล่า?)', en: 'Wow! Price up 2%! This is amazing! (Or is it?)'),
    NpcQuote(th: 'ฉันพึ่งเรียนรู้เรื่อง P/E ratio เมื่อวานนี้เอง!', en: 'I just learned about P/E ratios yesterday!'),
    NpcQuote(th: 'กาแฟคือเชื้อเพลิงของ Wall Street — ฉันรู้จักงานหลักของฉัน', en: "Coffee is Wall Street's fuel — I know my primary job."),
    NpcQuote(th: 'เจ้านายบอกให้ซื้อ "blue chip" ฉันกำลังหาว่า chip สีน้ำเงินอยู่ที่ไหน', en: 'Boss said buy "blue chips." I\'m still looking for which ones are literally blue.'),
    NpcQuote(th: 'ฉันทำ Excel model พัง 3 ครั้งแล้ว แต่ครั้งที่ 4 จะต้องสมบูรณ์แบบ!', en: "I've broken the Excel model 3 times. The 4th will be perfect!"),
    NpcQuote(th: 'งาน intern วันแรก: ถ่ายเอกสาร 500 หน้า. ความฝัน: เป็น fund manager', en: 'Day 1 intern: photocopied 500 pages. Dream: become a fund manager.'),
    NpcQuote(th: 'สูตร DCF มันซับซ้อนมาก แต่ฉันจะเรียนรู้ให้ได้!', en: 'DCF formula is really complex, but I will master it!'),
    NpcQuote(th: 'ฉันอ่าน "The Intelligent Investor" จบแล้ว! (ข้ามบางหน้า)', en: '"The Intelligent Investor" — finished! (skipped some pages)'),
    NpcQuote(th: 'Bloomberg Terminal ดูน่ากลัวมาก... ปุ่มเยอะเกิน', en: 'The Bloomberg Terminal looks terrifying... so many buttons.'),
    NpcQuote(th: 'วันนี้ฉันถามพี่ว่า "bull market" กับ "bear market" ต่างกันอย่างไร', en: 'Today I asked my senior what the difference between a bull and bear market is.'),
    NpcQuote(th: 'เจ้านายให้ทำ research report ส่งพรุ่งนี้ ฉันกำลังเริ่มหน้าแรก', en: 'Boss wants the research report tomorrow. I\'m on page one.'),
    NpcQuote(th: 'ฉัน copy สูตรจาก Stack Overflow มาใส่ใน model — มันทำงานได้!', en: 'I copied a formula from Stack Overflow into the model — it works!'),
    NpcQuote(th: 'เพื่อนบอกว่าซื้อหุ้น "meme" ฉันไม่แน่ใจนักว่าดีไหม...', en: 'Friends say buy meme stocks. I\'m not so sure about that...'),
    NpcQuote(th: 'กาแฟ 3 แก้วแล้ว ยังงัวเงียอยู่เลย — Wall Street ไม่ใช่สำหรับคนอ่อนแอ', en: '3 coffees in and still groggy — Wall Street is not for the weak.'),
    NpcQuote(th: 'ฉันพิมพ์ผิดใน pitch deck... ใส่ล้านเป็นพันล้าน... เจ้านายเห็นแล้ว...', en: 'I mistyped in the pitch deck... put million instead of billion... boss saw it...'),
    NpcQuote(th: 'วันนี้ฉันเรียนรู้ว่า short selling คืออะไร และมันน่ากลัวมาก', en: 'Today I learned what short selling is. It\'s terrifying.'),
    NpcQuote(th: 'ฉันยังไม่เข้าใจ options... แต่ทุกคนดูเหมือนเข้าใจ', en: "I still don't understand options... but everyone else seems to."),
    NpcQuote(th: 'Intern เดือนที่ 2: ฉันรู้แล้วว่า "liquidity" ไม่ใช่เรื่องน้ำ', en: "Intern month 2: I now know 'liquidity' isn't about actual liquid."),
    NpcQuote(th: 'ฉันตั้งใจฟังทุกคำพูดของ senior analyst — มันน่าทึ่งมาก', en: 'I listen to every word from the senior analyst — it\'s incredible.'),
    NpcQuote(th: 'สิ่งที่ยากที่สุดในการเป็น intern คือ pretend ว่าเข้าใจทุกอย่าง', en: 'The hardest part of being an intern is pretending to understand everything.'),
    NpcQuote(th: 'ฉันทำ cold call ครั้งแรกวันนี้ เขาวางสายก่อนฉันพูดจบ...', en: 'Made my first cold call today. They hung up before I finished.'),
    NpcQuote(th: 'เป้าหมายของฉัน: ภายใน 5 ปี จะมีพอร์ตของตัวเอง', en: 'My goal: in 5 years, I\'ll have my own portfolio.'),
    NpcQuote(th: 'วันนี้เข้าประชุม board ครั้งแรก — ฉันไม่กล้าพูดอะไรเลยสักคำ', en: 'Attended my first board meeting today. Didn\'t say a single word.'),
    NpcQuote(th: 'ฉันเพิ่งลงทุนครั้งแรก 1,000 บาท มันน่าตื่นเต้นมาก!', en: 'Made my first investment — 1,000 baht. So exciting!'),
    NpcQuote(th: 'ทุกคนบนชั้น 30 ดูยุ่งมาก ฉันแค่พยายามไม่ชนโต๊ะใคร', en: "Everyone on floor 30 looks so busy. I'm just trying not to bump into anyone's desk."),
    NpcQuote(th: 'ฉันเอา report ให้เจ้านายผิดคน... แต่ก็ผ่านไปแล้ว', en: 'I handed the report to the wrong person... but we\'re past it now.'),
    NpcQuote(th: 'ถามเพื่อน: YOLO แปลว่าอะไร? เพื่อนตอบ: อย่าทำ', en: 'Asked a friend what YOLO means. Friend said: just don\'t.'),
    NpcQuote(th: 'ฉันฝันว่าวันหนึ่งจะมีออฟฟิศมุมที่มองเห็นวิวทั้งเมือง', en: 'I dream of having a corner office overlooking the whole city one day.'),
    NpcQuote(th: 'ความผิดพลาดทุกครั้งคือบทเรียน... ฉันบอกตัวเองแบบนี้ทุกวัน', en: 'Every mistake is a lesson... I tell myself that every single day.'),
    NpcQuote(th: 'วันนี้พี่ชมว่าฉันทำงานดี ฉันแฮปปี้มากจนลืมกินข้าว', en: 'Senior praised my work today. I was so happy I forgot to eat lunch.'),
  ],
};
