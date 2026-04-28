import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:student_quiz_app/presentation/providers/result_provider.dart';
import 'package:student_quiz_app/domain/repositories/result_repository.dart';
import 'package:student_quiz_app/data/sources/local/local_storage.dart';

class MockResultRepository extends Mock implements ResultRepository {}
class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late ResultProvider provider;
  late MockResultRepository mockResultRepository;
  late MockLocalStorage mockLocalStorage;

  setUp(() {
    mockResultRepository = MockResultRepository();
    mockLocalStorage = MockLocalStorage();
    provider = ResultProvider(
      repository: mockResultRepository,
      localStorage: mockLocalStorage,
    );
  });

  group('ResultProvider', () {
    test('getStudentHistory sets error on failure', () async {
      // Arrange
      when(() => mockLocalStorage.getToken()).thenAnswer((_) async => 'fake_token');
      when(() => mockResultRepository.fetchStudentHistory('fake_token'))
          .thenThrow(Exception('API Error'));

      // Act
      final result = await provider.getStudentHistory();

      // Assert
      expect(result, isEmpty);
      expect(provider.error, 'Failed to load history');
      expect(provider.isLoading, isFalse);
    });
  });
}
