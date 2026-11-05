<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use App\Service\ExecutableCommands\ExecutableCommandService;

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
            $this->executableCommandService->exec(new Command('ls -la'))
        );
        return $this->render('index/index.html.twig', [
            'controller_name' => 'IndexController',
        ]);
    }
}
