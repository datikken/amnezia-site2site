<?php

namespace App\Service\ExecutableCommands\AwgShow;

use App\Service\ExecutableCommands\ExecutableCommandService;

/**
 * High level service that runs `awg show` and returns the parsed peers.
 */
final readonly class AwgShowService
{
    public function __construct(
        private ExecutableCommandService $executableCommandService,
        private AwgShowParser $awgShowParser,
    ) {
    }

    /**
     * @return list<array<string, string>>
     */
    public function getPeers(): array
    {
        $output = $this->executableCommandService->exec(new AwgShowCommand());

        return $this->awgShowParser->parsePeers($output);
    }
}