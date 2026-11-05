<?php

namespace App\Service\ExecutableCommands\AwgShow;

final readonly class AwgShowParser
{
    public static function parse(string $output): array
    {
        $result  = ['interfaces' => [], 'peers' => []];
        $current = null;          // null | 'interface' | 'peer'
        $currentName = null;      // имя текущего интерфейса

        foreach (preg_split('/\r?\n/', $output) as $line) {
            $line = trim($line);
            if ($line === '') {
                continue;
            }

            // interface
            if (preg_match('/^interface:\s*(.+)$/i', $line, $m)) {
                $current = 'interface';
                $currentName = $m[1];
                $result['interfaces'][$currentName] = [];
                continue;
            }

            // peer
            if (preg_match('/^peer:\s*(\S+)$/i', $line, $m)) {
                $current = 'peer';
                $result['peers'][] = ['public_key' => $m[1]];
                continue;
            }

            if ($current === null) {
                continue;
            }

            // key: value
            if (preg_match('/^\s*([a-z0-9 _-]+):\s*(.*)$/i', $line, $m)) {
                $key = strtolower(str_replace(' ', '_', trim($m[1])));
                $value = trim($m[2]);

                if ($current === 'interface' && $currentName !== null) {
                    $result['interfaces'][$currentName][$key] = $value;
                } elseif ($current === 'peer') {
                    // берём последний пир
                    $lastIndex = count($result['peers']) - 1;
                    if ($lastIndex >= 0) {
                        $result['peers'][$lastIndex][$key] = $value;
                    }
                }
            }
        }

        return $result;
    }

    public static function parsePeers(string $output): array
    {
        return self::parse($output)['peers'];
    }
}
