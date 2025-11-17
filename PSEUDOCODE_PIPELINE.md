# PiCom 데이터 파이프라인 수도코드
# 엑셀 → Firestore (listings + base_parts + priceHistory)

## =============================================================================
## PHASE 0: 엑셀 파일 준비
## =============================================================================

"""
필수 컬럼 추가:
1. CPU.xlsx → "소켓" 컬럼 추가
2. Mainboard.xlsx → "소켓", "메모리 타입", "폼팩터" 컬럼 추가
3. RAM.xlsx → 이미 "메모리 규격" 있음 ✅
4. (선택) GPU.xlsx → "TDP (W)" 컬럼 추가
5. (선택) SSD.xlsx → "인터페이스" 컬럼 추가
"""

## =============================================================================
## PHASE 1: 필드명 매핑 정의
## =============================================================================

FIELD_MAPPING = {
  'CPU': {
    excel_fields: {
      brand: '브랜드',
      series: '시리즈',
      modelNumber: '모델 번호',
      suffix: '접미사',
      socket: '소켓',              # 🆕 추가
      price: '판매가',
      referencePrice: '신제품 판매가',
      likes: '좋아요 수',
      chats: '채팅 수',
      views: '조회수',
      isSealed: '미개봉 여부',
      images: ['사진1', '사진2', '사진3', '사진4', '사진5'],
      createdDate: '판매글 게시일자',
    },
    basePartId_format: '{brand}_{series}_{modelNumber}_{suffix}',
    modelName_format: '{brand} {series} {modelNumber} {suffix}',
    brand_field: 'brand',
  },

  'GPU': {
    excel_fields: {
      brand: '브랜드',
      manufacturer: '제조사',
      series: '시리즈',
      modelNumber: '모델 번호',
      suffix: '접미사',
      detailModel: '세부 모델명',
      memory: '메모리 용량',
      tdp: 'TDP (W)',              # 🆕 추가 (선택)
      price: '판매가',
      referencePrice: '신제품 판매가',
      likes: '좋아요 수',
      chats: '채팅 수',
      views: '조회수',
      isSealed: '미개봉 여부',
      images: ['사진1', '사진2', '사진3', '사진4', '사진5'],
      createdDate: '판매글 게시일자',
    },
    basePartId_format: '{brand}_{series}{modelNumber}_{suffix}_{memory}',
    modelName_format: '{brand} {series} {modelNumber} {suffix} {detailModel} {memory}',
    brand_field: 'manufacturer',
  },

  'Mainboard': {
    excel_fields: {
      manufacturer: '제조사',
      series: '시리즈',
      chipset: '칩셋',
      modelName: '모델명',
      detail1: '세부특징1',
      detail2: '세부특징2',
      socket: '소켓',              # 🆕 추가
      memoryType: '메모리 타입',   # 🆕 추가
      formFactor: '폼팩터',        # 🆕 추가
      price: '판매가',
      referencePrice: '신제품 판매가',
      likes: '좋아요 수',
      chats: '채팅 수',
      views: '조회수',
      isSealed: '미개봉 여부',
      images: ['사진1', '사진2', '사진3', '사진4', '사진5'],
      createdDate: '판매글 게시일자',
    },
    basePartId_format: '{manufacturer}_{chipset}_{series}_{modelName}_{detail1}_{detail2}',
    modelName_format: '{manufacturer} {chipset} {series} {modelName} {detail1} {detail2}',
    brand_field: 'manufacturer',
  },

  'RAM': {
    excel_fields: {
      manufacturer: '제조사',
      memoryType: '메모리 규격',   # DDR4, DDR5
      seriesModel: '시리즈/모델명',
      clock: '클럭 (MHz)',
      capacity: '용량 (GB)',
      quantity: '판매 개수',
      pricePerUnit: '판매가(개당)',
      referencePrice: '신제품 판매가',
      likes: '좋아요 수',
      chats: '채팅 수',
      views: '조회수',
      isSealed: '미개봉 여부',
      images: ['사진1', '사진2', '사진3', '사진4', '사진5'],
      createdDate: '판매글 게시일자',
    },
    basePartId_format: '{manufacturer}_{memoryType}_{capacity}GB_{clock}MHz',
    modelName_format: '{manufacturer} {memoryType} {capacity}GB {clock}MHz {seriesModel}',
    brand_field: 'manufacturer',
    # 특수 처리: 총 가격 = pricePerUnit * quantity
  },

  'SSD': {
    excel_fields: {
      manufacturer: '제조사',
      seriesModel: '시리즈/모델명',
      formFactor: '폼팩터',
      capacity: '용량',
      interface: '인터페이스',     # 🆕 추가 (선택)
      price: '판매가',
      referencePrice: '신제품 판매가',
      likes: '좋아요 수',
      chats: '채팅 수',
      views: '조회수',
      isSealed: '미개봉 여부',
      images: ['사진1', '사진2', '사진3', '사진4', '사진5'],
      createdDate: '판매글 게시일자',
    },
    basePartId_format: '{manufacturer}_{seriesModel}_{capacity}',
    modelName_format: '{manufacturer} {seriesModel} {formFactor} {capacity}',
    brand_field: 'manufacturer',
  },
}

## =============================================================================
## PHASE 2: 텍스트 정규화 함수
## =============================================================================

FUNCTION sanitize(text):
  """
  basePartId용 텍스트 정규화
  - 공백 → 언더스코어
  - 특수문자 제거 (영문, 숫자, 한글, -, _ 만 허용)
  - 빈 값 → 빈 문자열
  """
  IF text IS NULL OR text IS EMPTY:
    RETURN ""
  
  # 공백을 언더스코어로
  text = text.TRIM().REPLACE(/\s+/g, '_')
  
  # 특수문자 제거 (영문, 숫자, 한글, -, _ 제외)
  text = text.REPLACE(/[^\w가-힣-]/g, '')
  
  RETURN text

FUNCTION normalizeForModelName(text):
  """
  modelName용 텍스트 정규화
  - 공백 유지 (여러 개 → 하나로)
  - 특수문자 일부 허용
  """
  IF text IS NULL OR text IS EMPTY:
    RETURN ""
  
  RETURN text.TRIM().REPLACE(/\s+/g, ' ')

## =============================================================================
## PHASE 3: basePartId 생성 함수
## =============================================================================

FUNCTION generateBasePartId(category, excelRow):
  """
  카테고리별 basePartId 생성
  """
  mapping = FIELD_MAPPING[category]
  fields = mapping.excel_fields
  
  # 엑셀 행에서 필드 추출 및 정규화
  extractedFields = {}
  FOR EACH (fieldName, excelColumn) IN fields:
    IF fieldName NOT IN ['images', 'price', 'referencePrice', ...]:
      rawValue = excelRow[excelColumn]
      extractedFields[fieldName] = sanitize(rawValue)
  
  # 형식 문자열에 따라 조합
  format = mapping.basePartId_format
  parts = []
  
  # 예: '{brand}_{series}_{modelNumber}_{suffix}'
  FOR EACH placeholder IN format.split('_'):
    fieldName = placeholder.strip('{}')
    value = extractedFields[fieldName]
    IF value IS NOT EMPTY:
      parts.APPEND(value)
  
  basePartId = parts.JOIN('_')
  
  RETURN basePartId

EXAMPLE:
  CPU 행: {브랜드: 'AMD', 시리즈: 'Ryzen', 모델 번호: '5', 접미사: '5600X'}
  → sanitize('AMD') = 'AMD'
  → sanitize('Ryzen') = 'Ryzen'
  → sanitize('5') = '5'
  → sanitize('5600X') = '5600X'
  → basePartId = 'AMD_Ryzen_5_5600X'

## =============================================================================
## PHASE 4: modelName 생성 함수
## =============================================================================

FUNCTION generateModelName(category, excelRow):
  """
  사용자에게 보여줄 모델명 생성
  """
  mapping = FIELD_MAPPING[category]
  fields = mapping.excel_fields
  
  # 엑셀 행에서 필드 추출
  extractedFields = {}
  FOR EACH (fieldName, excelColumn) IN fields:
    IF fieldName NOT IN ['images', 'price', ...]:
      rawValue = excelRow[excelColumn]
      extractedFields[fieldName] = normalizeForModelName(rawValue)
  
  # 형식 문자열에 따라 조합
  format = mapping.modelName_format
  parts = []
  
  FOR EACH placeholder IN format.split(' '):
    fieldName = placeholder.strip('{}')
    value = extractedFields[fieldName]
    IF value IS NOT EMPTY:
      parts.APPEND(value)
  
  modelName = parts.JOIN(' ')
  
  RETURN modelName

EXAMPLE:
  CPU 행: {브랜드: 'AMD', 시리즈: 'Ryzen', 모델 번호: '5', 접미사: '5600X'}
  → modelName = 'AMD Ryzen 5 5600X'

## =============================================================================
## PHASE 5: brand 추출 함수
## =============================================================================

FUNCTION extractBrand(category, excelRow):
  """
  브랜드 필드 추출
  """
  mapping = FIELD_MAPPING[category]
  brandFieldName = mapping.brand_field
  excelColumn = mapping.excel_fields[brandFieldName]
  
  RETURN excelRow[excelColumn] OR ''

EXAMPLE:
  CPU: brand_field = 'brand' → excelRow['브랜드'] = 'AMD'
  GPU: brand_field = 'manufacturer' → excelRow['제조사'] = 'ASUS'

## =============================================================================
## PHASE 6: conditionScore 계산 (v5 알고리즘)
## =============================================================================

FUNCTION calculateConditionScore(excelRow):
  """
  상태 점수 계산 (55~95점)
  
  로직:
  1. 미개봉 → 95점
  2. 가격 비율로 기본 점수 (55~83점)
  3. 관심도 보정 (-5~+12점)
  4. 최종 범위: 55~90점 (일반 중고 최대 90점)
  """
  
  # 1. 가격 파싱
  price = parsePrice(excelRow['판매가'])
  referencePrice = parsePrice(excelRow['신제품 판매가'])
  likes = parseInt(excelRow['좋아요 수']) OR 0
  chats = parseInt(excelRow['채팅 수']) OR 0
  views = parseInt(excelRow['조회수']) OR 0
  isSealed = (excelRow['미개봉 여부'] == 'O')
  
  # 2. 미개봉 처리
  IF isSealed:
    RETURN 95
  
  # 3. 신제품 가격 없으면 기본값
  IF referencePrice == 0:
    RETURN 70
  
  # 4. 가격 비율 계산
  priceRatio = price / referencePrice
  
  # 5. 가격 비율 → 기본 점수
  IF priceRatio < 0.4:
    baseScore = 55 + (priceRatio / 0.4) * 5          # 0~40% → 55~60점
  ELSE IF priceRatio < 0.5:
    baseScore = 60 + ((priceRatio - 0.4) / 0.1) * 5  # 40~50% → 60~65점
  ELSE IF priceRatio < 0.6:
    baseScore = 65 + ((priceRatio - 0.5) / 0.1) * 5  # 50~60% → 65~70점
  ELSE IF priceRatio < 0.7:
    baseScore = 70 + ((priceRatio - 0.6) / 0.1) * 3  # 60~70% → 70~73점
  ELSE IF priceRatio < 0.8:
    baseScore = 73 + ((priceRatio - 0.7) / 0.1) * 3  # 70~80% → 73~76점
  ELSE IF priceRatio < 0.9:
    baseScore = 76 + ((priceRatio - 0.8) / 0.1) * 4  # 80~90% → 76~80점
  ELSE:
    baseScore = 80 + MIN((priceRatio - 0.9) / 0.1 * 3, 3)  # 90%+ → 80~83점
  
  # 6. 관심도 점수 계산
  interestRaw = chats * 3 + likes * 1.5 + views * 0.01
  
  IF interestRaw < 5:
    interestAdjustment = -5 + (interestRaw / 5) * 5        # 0~5 → -5~0점
  ELSE IF interestRaw < 15:
    interestAdjustment = (interestRaw - 5) / 10 * 4        # 5~15 → 0~4점
  ELSE IF interestRaw < 30:
    interestAdjustment = 4 + (interestRaw - 15) / 15 * 4   # 15~30 → 4~8점
  ELSE IF interestRaw < 50:
    interestAdjustment = 8 + (interestRaw - 30) / 20 * 3   # 30~50 → 8~11점
  ELSE:
    interestAdjustment = 11 + MIN((interestRaw - 50) / 50 * 1, 1)  # 50+ → 11~12점
  
  # 7. 최종 점수
  score = baseScore + interestAdjustment
  score = CLAMP(score, 55, 90)  # 일반 중고는 최대 90점
  
  RETURN ROUND(score * 10) / 10  # 소수점 1자리

## =============================================================================
## PHASE 7: 호환성 정보 추출
## =============================================================================

FUNCTION extractCompatibilityInfo(category, excelRow):
  """
  추천 시스템용 호환성 정보 추출
  """
  compatInfo = {}
  
  SWITCH category:
    CASE 'CPU':
      compatInfo.socket = excelRow['소켓'] OR NULL
      # 예: 'AM4', 'AM5', 'LGA1700'
    
    CASE 'GPU':
      compatInfo.vramSize = parseVramSize(excelRow['메모리 용량'])
      compatInfo.tdp = parseInt(excelRow['TDP (W)']) OR NULL
      # 예: vramSize: 12, tdp: 220
    
    CASE 'Mainboard':
      compatInfo.socket = excelRow['소켓'] OR NULL
      compatInfo.memoryType = excelRow['메모리 타입'] OR NULL
      compatInfo.formFactor = excelRow['폼팩터'] OR NULL
      # 예: socket: 'AM4', memoryType: 'DDR4', formFactor: 'ATX'
    
    CASE 'RAM':
      compatInfo.memoryType = excelRow['메모리 규격'] OR NULL
      compatInfo.capacity = parseInt(excelRow['용량 (GB)']) OR NULL
      compatInfo.speed = parseInt(excelRow['클럭 (MHz)']) OR NULL
      # 예: memoryType: 'DDR4', capacity: 16, speed: 3200
    
    CASE 'SSD':
      compatInfo.capacity = parseCapacity(excelRow['용량'])
      compatInfo.interface = excelRow['인터페이스'] OR NULL
      compatInfo.formFactor = excelRow['폼팩터'] OR NULL
      # 예: capacity: 1000, interface: 'NVMe', formFactor: 'M.2'
  
  RETURN compatInfo

FUNCTION parseVramSize(memoryText):
  """
  '12GB', '8GB' → 12, 8 (숫자만 추출)
  """
  IF memoryText IS EMPTY:
    RETURN NULL
  match = memoryText.MATCH(/(\d+)\s*GB/i)
  IF match:
    RETURN parseInt(match[1])
  RETURN NULL

FUNCTION parseCapacity(capacityText):
  """
  '1TB' → 1000
  '500GB' → 500
  '256GB' → 256
  """
  IF capacityText IS EMPTY:
    RETURN NULL
  
  IF capacityText.includes('TB'):
    value = parseFloat(capacityText)
    RETURN value * 1000
  ELSE IF capacityText.includes('GB'):
    RETURN parseInt(capacityText)
  
  RETURN NULL

## =============================================================================
## PHASE 8: Listing 문서 생성
## =============================================================================

FUNCTION createListingDocument(category, sheetName, excelRow):
  """
  Firestore listings 컬렉션 문서 생성
  """
  
  # 1. 기본 정보 생성
  basePartId = generateBasePartId(category, excelRow)
  modelName = generateModelName(category, excelRow)
  brand = extractBrand(category, excelRow)
  conditionScore = calculateConditionScore(excelRow)
  imageUrls = getImageUrls(excelRow)
  
  # 2. 가격 처리
  IF category == 'RAM':
    pricePerUnit = parsePrice(excelRow['판매가(개당)'])
    quantity = parseInt(excelRow['판매 개수']) OR 1
    price = pricePerUnit * quantity  # 총 가격
  ELSE:
    price = parsePrice(excelRow['판매가'])
  
  referencePrice = parsePrice(excelRow['신제품 판매가'])
  
  # 3. 호환성 정보 (base_parts에 전달할 정보)
  compatInfo = extractCompatibilityInfo(category, excelRow)
  
  # 4. 날짜 처리
  createdAt = parseDateFromExcel(excelRow['판매글 게시일자'])
  
  # 5. Listing 문서 생성
  listing = {
    listingId: generateUUID(),
    partId: basePartId,              # 레거시
    basePartId: basePartId,
    sellerId: SELLER_ID,
    brand: brand,
    modelName: modelName,
    price: price,
    referencePrice: referencePrice,
    conditionScore: conditionScore,
    imageUrls: imageUrls,
    status: 'available',             # 모든 데이터를 available로
    createdAt: createdAt,
    category: category,
    
    # 통계
    likesCount: parseInt(excelRow['좋아요 수']) OR 0,
    chatCount: parseInt(excelRow['채팅 수']) OR 0,
    viewCount: parseInt(excelRow['조회수']) OR 0,
    
    # 상태 정보
    isSealed: (excelRow['미개봉 여부'] == 'O'),
    ownershipTransfers: excelRow['소유권 이전횟수'] OR '모름',
    warrantyPeriod: excelRow['AS기간'] OR '모름',
    usageFrequency: excelRow['사용빈도'] OR '모름',
    purchaseDate: excelRow['구매일'] OR '모름',
    
    # 🆕 호환성 정보 (base_parts 생성 시 사용)
    _compatibilityInfo: compatInfo,  # 임시 필드 (listings에는 저장 안 함)
  }
  
  RETURN listing

## =============================================================================
## PHASE 9: 이미지 URL 생성
## =============================================================================

FUNCTION getImageUrls(excelRow):
  """
  Firebase Storage 이미지 URL 배열 생성
  """
  imageUrls = []
  baseUrl = 'https://firebasestorage.googleapis.com/v0/b/picom-team.firebasestorage.app/o/'
  
  FOR i IN [1, 2, 3, 4, 5]:
    filename = excelRow[`사진${i}`]
    IF filename IS NOT EMPTY:
      encodedPath = encodeURIComponent(`listings/${filename}`)
      url = `${baseUrl}${encodedPath}?alt=media`
      imageUrls.APPEND(url)
  
  RETURN imageUrls

## =============================================================================
## PHASE 10: 엑셀 파일 처리 (메인 로직)
## =============================================================================

FUNCTION processExcelFile(filePath, category):
  """
  엑셀 파일을 읽고 Firestore에 업로드
  """
  
  # 1. 엑셀 파일 읽기
  workbook = readExcelFile(filePath)
  targetSheets = ['거래완료', '예약중', '판매중']
  
  allListings = []
  
  # 2. 시트별 처리
  FOR EACH sheetName IN targetSheets:
    IF sheetName NOT IN workbook.sheetNames:
      CONTINUE
    
    sheet = workbook.getSheet(sheetName)
    rows = sheet.toJSON()
    
    # 3. 행별 처리
    FOR EACH row IN rows:
      # 가격이 없으면 스킵
      price = parsePrice(row['판매가'] OR row['판매가(개당)'])
      IF price == 0:
        CONTINUE
      
      TRY:
        listing = createListingDocument(category, sheetName, row)
        allListings.APPEND(listing)
      CATCH error:
        LOG_ERROR(`행 처리 실패: ${error.message}`)
        CONTINUE
  
  # 4. Firestore에 배치 업로드 (500개씩)
  batchSize = 500
  uploadedCount = 0
  
  FOR i IN RANGE(0, allListings.length, batchSize):
    batch = firestore.batch()
    batchListings = allListings[i : i + batchSize]
    
    FOR EACH listing IN batchListings:
      # _compatibilityInfo는 listings에 저장하지 않음
      listingForFirestore = {...listing}
      DELETE listingForFirestore._compatibilityInfo
      
      docRef = firestore.collection('listings').doc(listing.listingId)
      batch.set(docRef, listingForFirestore)
      uploadedCount++
    
    batch.commit()
    LOG_INFO(`${uploadedCount}개 업로드 완료`)
  
  RETURN uploadedCount

## =============================================================================
## PHASE 11: Cloud Functions - base_parts 자동 생성
## =============================================================================

"""
Cloud Functions가 자동으로 실행하는 로직
(index.ts의 recalculateBasePartStats 함수)
"""

CLOUD_FUNCTION onListingCreated(listingSnapshot):
  """
  Listing 생성 시 트리거
  """
  listing = listingSnapshot.data()
  
  IF listing.status == 'available' AND listing.basePartId:
    recalculateBasePartStats(listing.basePartId)

CLOUD_FUNCTION onListingUpdated(beforeSnapshot, afterSnapshot):
  """
  Listing 업데이트 시 트리거
  """
  before = beforeSnapshot.data()
  after = afterSnapshot.data()
  
  # status 변경 또는 price 변경 시 재계산
  IF (before.status != after.status) OR (before.price != after.price):
    IF after.basePartId:
      recalculateBasePartStats(after.basePartId)

CLOUD_FUNCTION onListingDeleted(listingSnapshot):
  """
  Listing 삭제 시 트리거
  """
  listing = listingSnapshot.data()
  
  IF listing.basePartId:
    recalculateBasePartStats(listing.basePartId)

## =============================================================================
## PHASE 12: base_parts 통계 재계산
## =============================================================================

FUNCTION recalculateBasePartStats(basePartId):
  """
  특정 basePartId의 통계 재계산 및 base_parts 생성/업데이트
  """
  
  # 1. 이전 통계 조회 (가격 변경 감지용)
  basePartRef = firestore.collection('base_parts').doc(basePartId)
  previousStats = basePartRef.get()
  
  # 2. available listings만 조회
  activeListings = firestore
    .collection('listings')
    .where('basePartId', '==', basePartId)
    .where('status', '==', 'available')
    .get()
  
  # 3. listings가 없으면 통계를 0으로
  IF activeListings.isEmpty:
    newStats = {
      lowestPrice: 0,
      averagePrice: 0,
      listingCount: 0,
    }
    basePartRef.set(newStats, {merge: true})
    
    # 가격 변경 감지
    IF previousStats AND statsChanged(previousStats, newStats):
      addPriceHistoryPoint(basePartId, newStats, previousStats)
    
    RETURN
  
  # 4. 가격 통계 계산
  firstListing = activeListings[0].data()
  prices = []
  
  FOR EACH listingDoc IN activeListings:
    listing = listingDoc.data()
    prices.APPEND(listing.price)
  
  lowestPrice = MIN(prices)
  averagePrice = AVG(prices)
  listingCount = prices.length
  
  # 5. 호환성 정보 수집 (첫 번째 listing에서)
  compatInfo = extractCompatibilityFromListing(firstListing)
  
  # 6. base_parts 문서 생성/업데이트
  basePartData = {
    basePartId: basePartId,
    modelName: firstListing.modelName,
    category: firstListing.category,
    brand: firstListing.brand,
    lowestPrice: lowestPrice,
    averagePrice: ROUND(averagePrice, 2),
    listingCount: listingCount,
    
    # 🆕 호환성 정보 (추천 시스템용)
    ...compatInfo,  # socket, memoryType, formFactor 등
  }
  
  basePartRef.set(basePartData, {merge: true})
  
  LOG_INFO(`base_parts 업데이트: ${basePartId}`)
  
  # 7. 가격 변경 감지 및 priceHistory 추가
  IF !previousStats OR statsChanged(previousStats, basePartData):
    addPriceHistoryPoint(basePartId, basePartData, previousStats)

FUNCTION extractCompatibilityFromListing(listing):
  """
  Listing에서 호환성 정보 추출
  (listings에는 저장되지 않았지만, 원본 데이터에서 다시 추출 가능)
  
  실제로는 listings에 호환성 정보를 저장하는 것이 더 효율적
  """
  
  # 방법 1: listings에 호환성 필드를 추가하는 방법 (권장)
  compatInfo = {}
  
  SWITCH listing.category:
    CASE 'CPU':
      compatInfo.socket = listing.socket  # listings에 저장된 경우
    CASE 'Mainboard':
      compatInfo.socket = listing.socket
      compatInfo.memoryType = listing.memoryType
      compatInfo.formFactor = listing.formFactor
    CASE 'RAM':
      compatInfo.memoryType = listing.memoryType
      compatInfo.capacity = listing.capacity
      compatInfo.speed = listing.speed
    # ... 기타 카테고리
  
  RETURN compatInfo

## =============================================================================
## PHASE 13: priceHistory 추가
## =============================================================================

FUNCTION addPriceHistoryPoint(basePartId, newStats, previousStats):
  """
  가격 변동 이력 추가
  """
  now = getCurrentTimestamp()
  docId = `${basePartId}_${now.toMillis()}`
  
  priceHistoryData = {
    basePartId: basePartId,
    timestamp: now,
    lowestPrice: newStats.lowestPrice,
    averagePrice: newStats.averagePrice,
    listingCount: newStats.listingCount,
    createdAt: now,
    
    # 변경 이력 (디버깅용)
    previousLowestPrice: previousStats?.lowestPrice OR NULL,
    previousAveragePrice: previousStats?.averagePrice OR NULL,
    previousListingCount: previousStats?.listingCount OR NULL,
  }
  
  firestore.collection('priceHistory').doc(docId).set(priceHistoryData)
  
  LOG_INFO(`priceHistory 추가: ${basePartId}`)

## =============================================================================
## PHASE 14: 메인 실행 함수
## =============================================================================

FUNCTION main():
  """
  전체 파이프라인 실행
  """
  
  LOG_INFO('🚀 Excel → Firestore 업로드 시작')
  
  files = [
    {path: 'datas/CPU.xlsx', category: 'CPU'},
    {path: 'datas/GPU.xlsx', category: 'GPU'},
    {path: 'datas/Mainboard.xlsx', category: 'Mainboard'},
    {path: 'datas/RAM.xlsx', category: 'RAM'},
    {path: 'datas/SSD.xlsx', category: 'SSD'},
  ]
  
  totalUploaded = 0
  
  FOR EACH file IN files:
    TRY:
      count = processExcelFile(file.path, file.category)
      totalUploaded += count
      LOG_INFO(`✅ ${file.category}: ${count}개 업로드 완료`)
    CATCH error:
      LOG_ERROR(`❌ ${file.category} 처리 실패: ${error.message}`)
      CONTINUE
  
  LOG_INFO(`✅ 전체 업로드 완료: 총 ${totalUploaded}개`)
  LOG_INFO('')
  LOG_INFO('📌 다음 단계:')
  LOG_INFO('  1. Firestore Console에서 listings 컬렉션 확인')
  LOG_INFO('  2. Cloud Functions가 자동으로 base_parts 생성 (1~2분 소요)')
  LOG_INFO('  3. base_parts 컬렉션 확인 (호환성 정보 포함)')
  LOG_INFO('  4. priceHistory 컬렉션 확인')
  LOG_INFO('  5. 추천 시스템 테스트')
  LOG_INFO('  6. 가격 차트 테스트')

## =============================================================================
## PHASE 15: 검증 체크리스트
## =============================================================================

"""
✅ 업로드 후 검증 사항:

1. listings 컬렉션 확인
   - 문서 개수가 엑셀 행 수와 일치하는지
   - basePartId가 올바르게 생성되었는지
   - 호환성 정보가 포함되었는지 (socket, memoryType 등)
   - conditionScore가 55~95 범위인지
   - imageUrls가 정상인지

2. base_parts 컬렉션 확인 (Cloud Functions 실행 후)
   - 문서 개수 = 고유 basePartId 개수
   - lowestPrice, averagePrice, listingCount가 정확한지
   - 호환성 정보가 포함되었는지 (socket, memoryType, formFactor 등)
   - modelName, category, brand가 정확한지

3. priceHistory 컬렉션 확인
   - 문서가 생성되었는지
   - timestamp가 최신인지

4. 추천 시스템 테스트
   - CPU-Mainboard 소켓 호환성 체크 작동
   - RAM-Mainboard 메모리 타입 호환성 체크 작동
   - 추천 결과가 나오는지

5. 가격 차트 테스트
   - priceHistory 데이터가 표시되는지
   - 최저가/평균가 라인이 정확한지
"""

## =============================================================================
## 끝
## =============================================================================
