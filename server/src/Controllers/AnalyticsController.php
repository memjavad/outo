<?php
namespace App\Controllers;

use App\Services\AnalyticsService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class AnalyticsController extends BaseController {
    
    public function getExamKpis(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $params = $request->getQueryParams();
        if (empty($params['exam_id'])) return $this->json($response, ["error" => "exam_id required"], 400);

        try {
            $service = new AnalyticsService();
            $data = $service->getExamKPIs((int)$params['exam_id']);
            return $this->json($response, ["status" => "success", "data" => $data]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }

    public function getDistractorAnalysis(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $params = $request->getQueryParams();
        if (empty($params['exam_id'])) return $this->json($response, ["error" => "exam_id required"], 400);

        try {
            $service = new AnalyticsService();
            $data = $service->getDistractorAnalysis((int)$params['exam_id']);
            return $this->json($response, ["status" => "success", "data" => $data]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }
}
