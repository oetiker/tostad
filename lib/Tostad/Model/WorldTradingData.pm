package Tostad::Model::WorldTradingData;
use Mojo::Base -base,-signatures,-async_await;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::File;
use Time::HiRes qw(time);
use Storable;

has apiToken => sub ($self) {
  $self->app->config->{DataSource}{WorldTradingData}{ApiToken};
};

has app => sub ($self) {
  die "app object missing";
};

has ua => sub ($self) {
  return $self->app->ua;
};

has delay => 0.05;

async sub sleep ($self,$delay) {
  return Mojo::Promise->new(sub ($resolve,$reject) {
    Mojo::IOLoop->timer($delay => sub { $resolve->() });
  });
}


has cache_file => sub ($self) {
  $self->app->home->rel_file("cache/full.store");
};

has cache_updated => sub { 0 };

has cache => sub ($self) {
    return eval {
      retrieve($self->cache_file)
    } // {};
};

sub DESTROY ($self) {
    if ($self->cache_updated ) {
        $self->cache_file->dirname->make_path;
        store $self->cache, $self->cache_file;
    }
}

my $last_time = 0;

async sub get ($self,$method,$query={}) {
  my $symbol = $query->{symbol};
  my $cache = $self->cache;
  if ($cache->{$symbol}) {
    return $cache->{$symbol};
  }
  # make sure we do not overwhelm
  my $interval = time - $last_time;
  if ($interval < $self->delay) {
    my $sleep = $self->delay - $interval;
    $last_time = time + $sleep;
    await $self->sleep($sleep);
  }
  my $tx = await $self->ua->get_p(
    Mojo::URL->new('https://api.worldtradingdata.com/api/v1/'.$method)
      ->query({api_token => $self->apiToken,%$query})
  )->catch(sub($err){
    warn $err;
    return {};
  });
  my $data = $tx->result->json;
  $self->cache_updated(1);
  return $cache->{$symbol} = $data;
}

1;
