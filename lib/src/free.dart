part of dartz;

// TODO: simplest possible implementation -- neither stack safe nor performant. add codensity/reassociation and trampolining.

abstract class Free<F, A> extends MonadOps<Free, A> {
  @override Free pure(a) => new Pure(a);

  foldMap(Monad G, f(_));
}

class Pure<F, A> extends Free<F, A> {
  final A _a;
  Pure(this._a);

  @override Free bind(Free f(A a)) => f(_a);

  @override foldMap(Monad G, f(_)) => G.pure(_a);

  @override bool operator ==(other) => other is Pure && other._a == _a;
}

class Bind<F, I, A> extends Free<F, A> {
  final F _i; // F<I>
  final Function _k; // I => Free[F, A]

  Bind(this._i, this._k);

  @override Free bind(Free f(A a)) => new Bind(_i, (i) => _k(i).bind(f));

  @override foldMap(Monad G, f(_)) => G.bind(f(_i), (a) => _k(a).foldMap(G, f));

  @override bool operator ==(other) => other is Bind && other._i == _i && other._k == _k;
}

final Monad<Free> FreeM = new MonadOpsMonad<Free>((a) => new Pure(a));

Free liftF(fa) => new Bind(fa, (a) => new Pure(a));