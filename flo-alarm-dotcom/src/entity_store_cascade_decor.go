package main

type entityCascade struct {
	base    EntityStore
	devRepo DeviceStore
}

func CreateEntityStoreCascade(base EntityStore, devRepo DeviceStore) EntityStore {
	return &entityCascade{base, devRepo}
}

func (ec *entityCascade) Ping() (e error) {
	if e = ec.base.Ping(); e == nil {
		e = ec.devRepo.Ping()
	}
	return
}

func (ec *entityCascade) Save(usr *LinkedUser) (bool, error) {
	return ec.base.Save(usr)
}

func (ec *entityCascade) Get(usrId string, sync bool) (*LinkedUser, error) {
	return ec.base.Get(usrId, sync)
}

func (ec *entityCascade) Delete(usrId string) (ok bool, e error) {
	if ok, e = ec.base.Delete(usrId); ok {
		if e = ec.devRepo.DeleteByUserId(usrId); e != nil {
			//TODO: pub kafka so other containers can flush local cache too
		}
	}
	return
}
