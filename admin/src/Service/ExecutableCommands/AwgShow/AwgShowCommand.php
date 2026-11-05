<?php

namespace App\Service\ExecutableCommands\AwgShow;

use App\Service\ExecutableCommands\Command;

final class AwgShowCommand extends Command
{
    public function getCommand(): array
    {
        return ['sudo', '-n', 'awg', 'show'];
    }
}