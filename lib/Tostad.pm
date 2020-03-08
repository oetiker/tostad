package Tostad;
use Mojo::Base 'Mojolicious', -signatures,-async_await;


sub startup ($self) {
  $self->plugin('Config',
    file => $self->home->rel_file('etc/tostad.cfg')
  );
  push @{$self->commands->namespaces}, __PACKAGE__.'::Command';

  # Configure the application
  $self->secrets($self->config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
}

1;
