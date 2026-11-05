<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use App\Service\ExecutableCommands\ExecutableCommandService;
use App\Service\ExecutableCommands\Command;
use App\Service\ExecutableCommands\AwgShowCommand;

final class IndexController extends AbstractController
{
    public function __construct(
        public readonly ExecutableCommandService $executableCommandService,
    ) {
    }

    #[Route('/', name: 'app_index')]
    public function index(): Response
    {
        dd(
            $this->executableCommandService->exec(new AwgShowCommand())
        );
        return $this->render('index/index.html.twig', [
            'controller_name' => 'IndexController',
        ]);
    }
}
