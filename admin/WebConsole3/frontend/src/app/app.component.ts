import {Component, OnInit} from '@angular/core';
import {LayoutService, LayoutStore} from 'angular-admin-lte';
import {AuthModule} from 'globunet-angular/core';
import {TranslateService} from '@ngx-translate/core';
import {OgCommonService} from './service/og-common.service';
import {AdminLteConf} from './admin-lte.conf';
import {User} from './model/user';
import {environment} from '../environments/environment';

@Component({
    selector: 'app-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
    public isCustomLayout: boolean;
    versionName = environment.version;

    constructor(private layoutService: LayoutService, private layoutStore: LayoutStore, private adminLteConfig: AdminLteConf, private authModule: AuthModule, private translate: TranslateService, private ogCommonService: OgCommonService) {

        translate.setDefaultLang('en');
        translate.use('es');
    }

    ngOnInit() {
        if (this.userIsLogged()) {
            this.ogCommonService.loadEngineConfig().subscribe(
                data => {

                    const user = <User>this.authModule.getLoggedUser();
                    this.ogCommonService.loadUserConfig();

                    this.layoutService.isCustomLayout.subscribe((value: boolean) => {
                        this.isCustomLayout = value;
                    });
                    this.layoutStore.setSidebarLeftMenu(this.adminLteConfig.get().sidebarLeftMenu);
                }
            );
        }
    }

    userIsLogged(): boolean {
        return true; //(this.authModule.getLoggedUser() && this.authModule.getLoggedUser().id !== 0);
    }
}
