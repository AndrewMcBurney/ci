import {Component, Inject, OnInit} from '@angular/core';
import {MAT_DIALOG_DATA} from '@angular/material';
import {Observable} from 'rxjs/Observable';

import {Repository} from '../../models/repository';
import {AddProjectRequest} from '../../services/data.service';

export interface AddProjectDialogConfig {
  repositories: Observable<Repository[]>;
}

interface TriggerOption {
  viewValue: string;
  value: 'commit'|'nightly';
}

interface TimeSelectorData {
  hour: number;
  isAm: boolean;
}

function timeSelectDataToMilitaryTime(timeData: TimeSelectorData): number {
  return this.timeSelectorData.hour * (this.timeSelectorData.isAm ? 1 : 2) % 24;
}

@Component({
  selector: 'fci-add-project-dialog',
  templateUrl: './add-project-dialog.component.html',
  styleUrls: ['./add-project-dialog.component.scss']
})
export class AddProjectDialogComponent implements OnInit {
  isLoadingRepositories = true;
  repositories: Repository[];
  readonly timeSelectorData: TimeSelectorData = {hour: 12, isAm: false};
  // TODO: do something to make these properties camelCase
  readonly project: AddProjectRequest = {
    lane: '',
    repo_org: '',
    repo_name: '',
    project_name: '',
    trigger_type: 'commit',
  };
  readonly TRIGGER_OPTIONS: TriggerOption[] = [
    {viewValue: 'for every commit and PR', value: 'commit'},
    {viewValue: 'nightly', value: 'nightly'},
  ];
  readonly HOURS: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  // TODO: get real lanes
  readonly FAKE_LANES: string[] = ['ios test', 'ios beta', 'ios deploy'];

  constructor(@Inject(MAT_DIALOG_DATA) private readonly data:
                  AddProjectDialogConfig) {}

  ngOnInit() {
    this.data.repositories.subscribe((repositories) => {
      this.repositories = repositories;
      this.project.repo_name = this.repositories[0].fullName;
      this.isLoadingRepositories = false;
    });

    // TODO Get Lanes
    this.project.lane = this.FAKE_LANES[0];
  }
  addProject() {
    if (this.project.trigger_type === 'nightly') {
      this.project.hour = timeSelectDataToMilitaryTime(this.timeSelectorData);
    }

    console.log('Project: ', this.project);
  }
}
