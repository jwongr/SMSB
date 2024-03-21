#!/usr/bin/env python
# coding: utf-8
import pandas as pd

df = pd.read_csv('temp_pka_changes.txt', delimiter='\s+')


df_above_7 = df[df['model_pka'] > 7]
df_below_7 = df[df['model_pka'] <= 7]

unprotonate = df_above_7[(df_above_7['pka'] < df_above_7['model_pka']) & (df_above_7['pka'] < 7)]
print('We need to unprotonate: ')
print(unprotonate)

protonate = df_below_7[(df_below_7['pka'] > df_below_7['model_pka']) & (df_below_7['pka'] > 7)]
print('We need to protonate: ')
print(protonate)
