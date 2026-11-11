<?php

namespace App\Controller\Admin;

use App\Service\ExecutableCommands\AwgShow\AwgShowCommand;
use App\Service\ExecutableCommands\AwgShow\AwgShowParser;
use App\Service\ExecutableCommands\ExecutableCommandService;
use EasyCorp\Bundle\EasyAdminBundle\Attribute\AdminDashboard;
use EasyCorp\Bundle\EasyAdminBundle\Config\Dashboard;
use EasyCorp\Bundle\EasyAdminBundle\Config\MenuItem;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractDashboardController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[AdminDashboard(routePath: '/admin', routeName: 'admin')]
#[IsGranted('ROLE_ADMIN')]
class DashboardController extends AbstractDashboardController
{
    public function __construct(
        private readonly ExecutableCommandService $executableCommandService,
        private readonly AwgShowParser $awgShowParser,
    ) {
    }

    public function index(): Response
    {
        $peers = $this->awgShowParser->parsePeers(
            $this->executableCommandService->exec(new AwgShowCommand())
        );

        return $this->render('admin/dashboard.html.twig', [
            'peers' => $peers,
        ]);
    }

    public function configureDashboard(): Dashboard
    {
        return Dashboard::new()
            ->setTitle('Admin')
            ->setFaviconPath('favicon.svg');
    }

    public function configureMenuItems(): iterable
    {
        yield MenuItem::linkToDashboard('Dashboard', 'fa fa-home');
        // yield MenuItem::linkTo(SomeCrudController::class, 'The Label', 'fas fa-list');
    }
}

