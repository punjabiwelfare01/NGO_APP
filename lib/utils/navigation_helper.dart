import 'package:flutter/material.dart';
import '../models/event_models.dart';

void openEvent(BuildContext context, EventModel event, {VoidCallback? onRefresh}) {
  final routeName = switch (event.eventType) {
    EventType.dailyChallenge => '/daily-challenge/${event.id}',
    EventType.quiz => '/quiz-event/${event.id}',
    EventType.workshop => '/workshop/${event.id}',
    EventType.competition => '/competition/${event.id}',
    EventType.scholarship => '/scholarship/${event.id}',
    EventType.counsellingDrive => '/counselling-drive/${event.id}',
    EventType.talentHunt => '/talent-hunt/${event.id}',
    EventType.awarenessCampaign => '/awareness-campaign/${event.id}',
    EventType.cyberSecurity => '/cyber-security/${event.id}',
    EventType.stationeryDrive ||
    EventType.donationDrive ||
    EventType.schoolPartnership ||
    EventType.communityOutreach => '/event/${event.id}',
  };
  Navigator.of(context).pushNamed(routeName).then((_) {
    if (onRefresh != null) {
      onRefresh();
    }
  });
}
