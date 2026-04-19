<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Core\Validator;

class ExamServiceTest extends TestCase {
    
    public function testValidatorRejectsEmptyTitle() {
        $data = ['title' => ''];
        $v = Validator::validate($data, ['title' => 'required|string']);
        $this->assertFalse($v['passes']);
        $this->assertArrayHasKey('title', $v['errors']);
    }

    public function testValidatorAcceptsValidTitle() {
        $data = ['title' => 'Psychology 101'];
        $v = Validator::validate($data, ['title' => 'required|string']);
        $this->assertTrue($v['passes']);
        $this->assertEquals('Psychology 101', $v['validated']['title']);
    }

    public function testValidatorEnforcesNumericId() {
        $data = ['id' => 'abc'];
        $v = Validator::validate($data, ['id' => 'required|numeric']);
        $this->assertFalse($v['passes']);
    }
    
    public function testValidatorAcceptsNumericString() {
        $data = ['id' => '123'];
        $v = Validator::validate($data, ['id' => 'required|numeric']);
        $this->assertTrue($v['passes']);
        $this->assertEquals(123, $v['validated']['id']);
    }
}
