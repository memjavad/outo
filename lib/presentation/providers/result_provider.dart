import 'package:flutter/foundation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/result_repository.dart';
import '../../data/repositories/result_repository_impl.dart';
import '../../data/sources/remote/api_results.dart';
import '../../data/sources/local/local_storage.dart';

class ResultProvider extends ChangeNotifier {
  final ResultRepository _repository = ResultRepositoryImpl(remoteDataSource: ApiResults(), localDataSource: LocalStorage());
  final LocalStorage _localStorage = LocalStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> submitResult(QuizResult result) async {
      _setLoading(true);
      try {
          final token = await _localStorage.getToken();
          await _repository.submitQuizResult(result, token);
      } catch (e) {
          _error = 'Submission failed offline sync engaged.';
      }
      _setLoading(false);
  }

  Future<List<QuizResult>> getStudentHistory() async {
      _setLoading(true);
      try {
         final token = await _localStorage.getToken();
         if (token == null) return [];
         final r = await _repository.fetchStudentHistory(token);
         _setLoading(false);
         return r;
      } catch (e) {
         _error = 'Failed to load history';
         _setLoading(false);
         return [];
      }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
