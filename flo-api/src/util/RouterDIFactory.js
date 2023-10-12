
export default function RouterDIFactory(routeName, getRouter, destroyRouter) {
  const factory = app => {
    app.use(routeName, (req, res, next) => {
      getRouter(req.container)(req, res, next);

      if (destroyRouter) {
        res.on('finish', () => destroyRouter(req.container));
      }
    });
  };

  return factory;
}