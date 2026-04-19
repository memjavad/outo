<?php
namespace App\Core;

class Validator {
    
    /**
     * @param array $data The incoming request data
     * @param array $rules An associative array of rules e.g. ['title' => 'required|string', 'age' => 'numeric']
     * @return array ['passes' => bool, 'errors' => array, 'validated' => array]
     */
    public static function validate(array $data, array $rules): array {
        $errors = [];
        $validated = [];

        foreach ($rules as $field => $ruleString) {
            $value = isset($data[$field]) ? $data[$field] : null;
            $ruleList = explode('|', $ruleString);
            
            $isRequired = in_array('required', $ruleList);

            if ($isRequired && ($value === null || $value === '')) {
                $errors[$field][] = "The {$field} field is required.";
                continue;
            }

            // If not required and empty, skip other rules but add to validated if present
            if (!$isRequired && ($value === null || $value === '')) {
                if ($value !== null) {
                    $validated[$field] = $value;
                }
                continue;
            }

            foreach ($ruleList as $rule) {
                if ($rule === 'required') continue;

                if ($rule === 'numeric') {
                    if (!is_numeric($value)) {
                        $errors[$field][] = "The {$field} field must be numeric.";
                    } else {
                        $value = (float) $value;
                    }
                }

                if ($rule === 'string') {
                    if (!is_string($value)) {
                        $errors[$field][] = "The {$field} field must be a string.";
                    } else {
                        $value = trim($value);
                    }
                }
                
                if (strpos($rule, 'in:') === 0) {
                    $allowed = explode(',', substr($rule, 3));
                    if (!in_array($value, $allowed)) {
                        $errors[$field][] = "The {$field} field must be one of: " . implode(', ', $allowed) . ".";
                    }
                }
            }

            if (!isset($errors[$field])) {
                $validated[$field] = $value;
            }
        }

        return [
            'passes' => empty($errors),
            'errors' => $errors,
            'validated' => $validated
        ];
    }
}
