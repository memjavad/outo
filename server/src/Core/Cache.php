<?php
namespace App\Core;

use Symfony\Component\Cache\Adapter\FilesystemAdapter;
use Symfony\Contracts\Cache\ItemInterface;

class Cache {
    private static $adapter = null;

    private static function init() {
        if (self::$adapter === null) {
            self::$adapter = new FilesystemAdapter('app_cache', 0, __DIR__ . '/../../cache');
        }
    }

    /**
     * Fetch from cache, or invoke the callback to generate and save it.
     */
    public static function remember(string $key, int $ttl, callable $callback) {
        self::init();
        return self::$adapter->get($key, function (ItemInterface $item) use ($ttl, $callback) {
            $item->expiresAfter($ttl);
            return $callback();
        });
    }

    /**
     * Delete an item from the cache.
     */
    public static function delete(string $key) {
        self::init();
        self::$adapter->deleteItem($key);
    }
}
