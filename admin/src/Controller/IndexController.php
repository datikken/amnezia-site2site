<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use App\Service\ExecutableCommands\ExecutableCommandService;
use App\Service\ExecutableCommands\AwgShow\AwgShowCommand;
use App\Service\ExecutableCommands\AwgShow\AwgShowParser;

final class IndexController extends AbstractController
{
    public function __construct(
        public readonly ExecutableCommandService $executableCommandService,
        public readonly AwgShowParser $awgShowParser,
    ) {
    }

    #[Route('/', name: 'app_index')]
    public function index(): Response
    {
        dd(
            $this->awgShowParser->parse(
                $this->executableCommandService->exec(new AwgShowCommand())
            )
        );
        return $this->render('index/index.html.twig', [
            'controller_name' => 'IndexController',
        ]);
    }
}
