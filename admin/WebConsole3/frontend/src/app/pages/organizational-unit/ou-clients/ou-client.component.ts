import {Component, EventEmitter, Input, Output} from '@angular/core';
import {Client} from '../../../model/client';
import {ClientService} from '../../../api/client.service';
import {OgSweetAlertService} from '../../../service/og-sweet-alert.service';
import {ToasterService} from '../../../service/toaster.service';
import {TranslateService} from '@ngx-translate/core';
import {OrganizationalUnit} from '../../../model/organizational-unit';
import {OgCommonService} from '../../../service/og-common.service';

@Component({
  selector: 'app-ou-client-component',
  templateUrl: 'ou-client.component.html',
  styleUrls: ['ou-client.component.scss']
})
export class OuClientComponent {
  private _ou: OrganizationalUnit;
  public clients: Client[];
  @Input()
  set ou(ou) {
    this._ou = ou;
    this.clients = ou.clients;
  }
  get ou() {
    return this._ou;
  }
  @Input() selectedStatus;
  @Input() clientStatus;
  @Input() showGrid: boolean;

  @Output() clientSelected = new EventEmitter<Client>();


  constructor( private clientService: ClientService,
               private ogSweetAlert: OgSweetAlertService,
               private toaster: ToasterService,
               private translate: TranslateService,
               private ogCommonService: OgCommonService) {}

  selectClient(client) {
    this.ogCommonService.selectClient(client, this.ou);
    this.clientSelected.emit(client);
  }

  deleteClient(client) {
    const self = this;
    this.ogSweetAlert.swal(
      {
        title: this.translate.instant('sure_to_delete') + '?',
        text: this.translate.instant('action_cannot_be_undone'),
        type: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#DD6B55',
        confirmButtonText: this.translate.instant('yes_delete')

      }).then(
      function(response) {
        if (response.value === true) {
          self.clientService.delete(client.id).subscribe(
            (success) => {
              // Lo borramos de la unidad organizativa
              const index = self.ou.clients.indexOf(client);
              if (index !== -1) {
                self.ou.clients.splice(index, 1);
              }
              self.toaster.pop({type: 'success', title: 'success', body: 'Successfully deleted'});
            },
            (error) => {
              self.toaster.pop({type: 'error', title: 'error', body: error});
            }
          );
        }

      },
      function(cancel) {

      }
    );
  }

  mustShow(client) {
    let result = true;
    if (typeof this.clientStatus[client.id] !== 'undefined') {
      const status = this.clientStatus[client.id].id;
      if (status) {
        result = this.selectedStatus[status];
      }
    } else {
      // Si no se detectó el estado, se asigna no definido
      this.clientStatus[client.id] = {id: 0, name: 'undefined'};
    }

    return result;
  }
}
