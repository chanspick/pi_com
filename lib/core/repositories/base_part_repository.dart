import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_com/core/models/base_part_model.dart';

/// BasePart 데이터 조회를 위한 Repository
class BasePartRepository {
  final FirebaseFirestore _firestore;

  BasePartRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 카테고리별 재고가 있는 BasePart 조회
  ///
  /// [category] 부품 카테고리 (cpu, gpu, mainboard, ram, ssd, psu, cooler, case)
  /// [minListingCount] 최소 매물 수 (기본값: 1)
  ///
  /// Returns: 해당 카테고리의 BasePart 목록
  Future<List<BasePart>> getAvailablePartsByCategory(
    String category, {
    int minListingCount = 1,
  }) async {
    try {
      print('🔍 [BasePartRepository] Querying category="$category", minListingCount=$minListingCount');
      print('🌐 [BasePartRepository] Force fetching from SERVER (no cache)');

      final querySnapshot = await _firestore
          .collection('base_parts')
          .where('category', isEqualTo: category)
          .where('listingCount', isGreaterThanOrEqualTo: minListingCount)
          .get(const GetOptions(source: Source.server));

      final parts = querySnapshot.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();

      print('✅ [BasePartRepository] Found ${parts.length} parts for category="$category"');
      if (parts.isNotEmpty) {
        print('   Sample: ${parts.first.modelName} (${parts.first.listingCount} listings)');
      }

      return parts;
    } catch (e) {
      print('❌ Error fetching base parts for category $category: $e');
      return [];
    }
  }

  /// 모든 카테고리의 재고가 있는 BasePart 조회
  ///
  /// [minListingCount] 최소 매물 수 (기본값: 1)
  ///
  /// Returns: 카테고리별로 그룹화된 BasePart Map
  Future<Map<String, List<BasePart>>> getAllAvailableParts({
    int minListingCount = 1,
  }) async {
    final categories = ['cpu', 'gpu', 'mainboard', 'ram', 'ssd', 'psu', 'cooler', 'case'];
    final Map<String, List<BasePart>> result = {};

    for (final category in categories) {
      result[category] = await getAvailablePartsByCategory(
        category,
        minListingCount: minListingCount,
      );
    }

    return result;
  }

  /// 특정 스펙 조건으로 BasePart 조회
  ///
  /// 예: RAM 검색 - capacity: 16, memoryType: 'DDR4'
  /// 예: SSD 검색 - capacity: 1000, interface: 'NVMe'
  Future<List<BasePart>> getPartsBySpec({
    required String category,
    Map<String, dynamic>? specs,
    int minListingCount = 1,
  }) async {
    try {
      Query query = _firestore.collection('base_parts');

      // 카테고리 필터
      query = query.where('category', isEqualTo: category);

      // 재고 필터
      query = query.where('listingCount', isGreaterThanOrEqualTo: minListingCount);

      // 스펙 필터 적용
      if (specs != null) {
        specs.forEach((key, value) {
          if (value != null) {
            query = query.where(key, isEqualTo: value);
          }
        });
      }

      final querySnapshot = await query.get(const GetOptions(source: Source.server));

      return querySnapshot.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching parts by spec: $e');
      return [];
    }
  }

  /// 용량 범위로 RAM/SSD 조회
  ///
  /// [category] 'ram' 또는 'ssd'
  /// [minCapacity] 최소 용량 (GB)
  /// [maxCapacity] 최대 용량 (GB, null이면 무제한)
  Future<List<BasePart>> getPartsByCapacityRange({
    required String category,
    required int minCapacity,
    int? maxCapacity,
    int minListingCount = 1,
  }) async {
    try {
      Query query = _firestore
          .collection('base_parts')
          .where('category', isEqualTo: category)
          .where('listingCount', isGreaterThanOrEqualTo: minListingCount)
          .where('capacity', isGreaterThanOrEqualTo: minCapacity);

      if (maxCapacity != null) {
        query = query.where('capacity', isLessThanOrEqualTo: maxCapacity);
      }

      final querySnapshot = await query.get(const GetOptions(source: Source.server));

      return querySnapshot.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching parts by capacity: $e');
      return [];
    }
  }

  /// 소켓 타입으로 CPU/메인보드/쿨러 조회
  Future<List<BasePart>> getPartsBySocket({
    required String category,
    required String socket,
    int minListingCount = 1,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('base_parts')
          .where('category', isEqualTo: category)
          .where('socket', isEqualTo: socket)
          .where('listingCount', isGreaterThanOrEqualTo: minListingCount)
          .get(const GetOptions(source: Source.server));

      return querySnapshot.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching parts by socket: $e');
      return [];
    }
  }

  /// PSU 전력 범위로 조회
  Future<List<BasePart>> getPsuByWattageRange({
    required int minWattage,
    int? maxWattage,
    int minListingCount = 1,
  }) async {
    try {
      Query query = _firestore
          .collection('base_parts')
          .where('category', isEqualTo: 'psu')
          .where('listingCount', isGreaterThanOrEqualTo: minListingCount)
          .where('wattage', isGreaterThanOrEqualTo: minWattage);

      if (maxWattage != null) {
        query = query.where('wattage', isLessThanOrEqualTo: maxWattage);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => BasePart.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching PSU by wattage: $e');
      return [];
    }
  }

  /// 특정 BasePart ID로 조회
  Future<BasePart?> getBasePartById(String basePartId) async {
    try {
      final doc = await _firestore
          .collection('base_parts')
          .doc(basePartId)
          .get();

      if (!doc.exists) return null;

      return BasePart.fromFirestore(doc);
    } catch (e) {
      print('Error fetching base part by ID: $e');
      return null;
    }
  }
}
