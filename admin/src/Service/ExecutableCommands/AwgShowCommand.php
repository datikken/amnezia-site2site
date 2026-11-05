<?php

namespace App\Service\ExecutableCommands;

final class AwgShowCommand extends Command
{
    public function getCommand(): array
    {
        return ['sudo', '-n', 'awg', 'show'];
    }
}