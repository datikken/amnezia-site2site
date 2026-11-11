<?php

namespace App\Service\ExecutableCommands;

abstract class Command
{
    /**
     * @return list<string>
     */
    abstract public function getCommand(): array;
}