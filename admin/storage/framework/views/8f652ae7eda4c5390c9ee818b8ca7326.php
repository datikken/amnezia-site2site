<?php if(\Livewire\Mechanisms\ExtendBlade\ExtendBlade::isRenderingLivewireComponent()): ?><!--[if BLOCK]><![endif]--><?php endif; ?><?php if($response): ?>
<?php echo $response->head; ?>

<?php else: ?>
<?php echo $slot; ?>

<?php endif; ?><?php if(\Livewire\Mechanisms\ExtendBlade\ExtendBlade::isRenderingLivewireComponent()): ?><!--[if ENDBLOCK]><![endif]--><?php endif; ?><?php /**PATH /var/www/html/storage/framework/views/58f6b5ecbad88fc4da15879dbc7f6e69.blade.php ENDPATH**/ ?>