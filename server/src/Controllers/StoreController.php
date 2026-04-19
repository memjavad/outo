<?php
namespace App\Controllers;

use App\Core\Database;
use App\Core\Validator;
use App\Repositories\StoreRepository;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class StoreController extends BaseController {

    public function getItems(Request $request, Response $response, array $args): Response {
        $studentId = $request->getAttribute('student_id');
        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $storeRepo = new StoreRepository($db);

        try {
            $items = $storeRepo->getActiveItems();
            return $this->json($response, ["status" => "success", "items" => $items]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to fetch items"], 500);
        }
    }

    public function buyItem(Request $request, Response $response, array $args): Response {
        $studentId = $request->getAttribute('student_id');
        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $data = $request->getParsedBody() ?? [];
        $validation = Validator::validate($data, [
            'item_key' => 'required|string'
        ]);

        if (!$validation['passes']) return $this->json($response, ["error" => "Missing item_key"], 400);

        $db = Database::getInstance();
        $storeRepo = new StoreRepository($db);
        
        $itemKey = $validation['validated']['item_key'];
        $item = $storeRepo->getItemByKey($itemKey);

        if (!$item) return $this->json($response, ["error" => "Item not found"], 404);

        $success = $storeRepo->buyItem((int)$studentId, $itemKey, (int)$item['cost_points']);

        if ($success) {
            return $this->json($response, ["status" => "success", "message" => "Item purchased successfully"]);
        } else {
            return $this->json($response, ["error" => "Insufficient points or transaction failed"], 400);
        }
    }

    public function consumeItem(Request $request, Response $response, array $args): Response {
        $studentId = $request->getAttribute('student_id');
        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $data = $request->getParsedBody() ?? [];
        $validation = Validator::validate($data, [
            'item_key' => 'required|string'
        ]);

        if (!$validation['passes']) return $this->json($response, ["error" => "Missing item_key"], 400);

        $db = Database::getInstance();
        $storeRepo = new StoreRepository($db);
        
        $itemKey = $validation['validated']['item_key'];

        $success = $storeRepo->consumeItem((int)$studentId, $itemKey);

        if ($success) {
            return $this->json($response, ["status" => "success", "message" => "Item consumed successfully"]);
        } else {
            return $this->json($response, ["error" => "Item not owned or transaction failed"], 400);
        }
    }
}
