<?php

namespace App\Service\ExecutableCommands;

use Symfony\Component\Process\Process;

final class ExecutableCommandService
{
    public function exec(Command $command): string
    {
        $process = new Process($command->getCommand());
        $process->mustRun();

        return $process->getOutput();
    }
}
